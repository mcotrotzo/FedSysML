import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COLLECTOR_PATH = os.path.join(BASE_DIR, "lambda_functions", "collector")
FEEDBACK_PATH = os.path.join(BASE_DIR, "lambda_functions", "feedback")

class LambdaDeployer:
    def __init__(self, name: str, source_dir: str, handler: str = "lambda_function.lambda_handler", runtime: str = "python3.13", timeout: int = 30):
        self.name = name
        self.source_dir = source_dir
        self.handler = handler
        self.runtime = runtime
        self.timeout = timeout
        self.layers = []
        self.statements: list[dict] = [
            {"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}
        ]
        self.env_vars: dict[str, str] = {}

    def add_statement(self, effect: str, actions: list[str], resources: list[str]):
        self.statements.append({"Effect": effect, "Action": actions, "Resource": resources})
        return self

    def add_env(self, key: str, value: str):
        self.env_vars[key] = value
        return self

    def add_layer(self, layer_arn: str):
        self.layers.append(layer_arn)
        return self

    def generate(self) -> str:
        statements_tf = json.dumps(self.statements)
        env_block = "\n      ".join(f'{k} = "{v}"' for k, v in self.env_vars.items())
        layers_line = f"layers = [{', '.join(self.layers)}]" if self.layers else ""
        
        return f"""
data "archive_file" "{self.name}_zip" {{
  type        = "zip"
  source_dir  = "{self.source_dir}"
  output_path = "${{path.module}}/{self.name}_payload.zip"
}}

resource "aws_iam_role" "{self.name}_role" {{
  name = "{self.name}-role"
  assume_role_policy = jsonencode({{
    Version = "2012-10-17"
    Statement = [{{
      Effect    = "Allow"
      Principal = {{ Service = "lambda.amazonaws.com" }}
      Action    = "sts:AssumeRole"
    }}]
  }})
}}

resource "aws_iam_role_policy" "{self.name}_policy" {{
  role = aws_iam_role.{self.name}_role.id
  policy = jsonencode({{
    Version = "2012-10-17"
    Statement = {statements_tf}
  }})
}}

resource "aws_lambda_function" "{self.name}" {{
  filename         = data.archive_file.{self.name}_zip.output_path
  source_code_hash = data.archive_file.{self.name}_zip.output_base64sha256
  function_name    = "{self.name}"
  role             = aws_iam_role.{self.name}_role.arn
  handler          = "{self.handler}"
  runtime          = "{self.runtime}"
  timeout          = {self.timeout}
  {layers_line}

  environment {{
    variables = {{
      {env_block}
    }}
  }}
}}"""

class TerraformConfig:
    def __init__(self, fed_config):
        self.fed_config = fed_config
        self.tf_blocks: list[str] = []

    def _prepare_paho_layer(self, output_dir: str):
        layer_path = os.path.join(output_dir, "paho_layer")
        site_packages = os.path.join(layer_path, "python")
        os.makedirs(site_packages, exist_ok=True)
        
        zip_file = os.path.join(output_dir, "paho_layer.zip")
        if not os.path.exists(zip_file):
            import subprocess
            subprocess.check_call(["pip", "install", "paho-mqtt", "-t", site_packages])
            
            import zipfile
            with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zf:
                for root, _, files in os.walk(layer_path):
                    for file in files:
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, layer_path)
                        zf.write(full_path, rel_path)
        
        self.tf_blocks.append(f"""
resource "aws_lambda_layer_version" "paho_mqtt" {{
  filename            = "paho_layer.zip"
  layer_name          = "paho_mqtt_layer"
  compatible_runtimes = ["python3.13"]
}}""")

    def generate(self, output_path: str):
        out_dir = os.path.dirname(output_path)
        self._create_providers()
        self._prepare_paho_layer(out_dir)
        
        all_new_strategies = []
        for fed_twin in self.fed_config.fedTwinConfig.fedTwins:
            for new_strategy in fed_twin.newStrategies:
                self._create_workflow(new_strategy)
                all_new_strategies.append(new_strategy)
        
        self._create_ssm_parameters(all_new_strategies)

        with open(output_path, "w") as f:
            f.write("\n\n".join(self.tf_blocks))

    def _create_providers(self):
        seen_regions = set()
        for twin in self.fed_config.twins.values():
            if twin.region in seen_regions: continue
            seen_regions.add(twin.region)
            alias = twin.region.replace("-", "_")
            self.tf_blocks.append(f'provider "aws" {{\n  alias  = "{alias}"\n  region = "{twin.region}"\n}}')

    def _create_feedback_lambda(self, new_strategy):
        feedback = new_strategy.feedback
        deployer = LambdaDeployer(f"{new_strategy.name}_feedback", FEEDBACK_PATH)
        deployer.add_env("FEEDBACK_TYPE", feedback.type).add_env("FEEDBACK_TOPIC", feedback.topic)
        deployer.add_layer("aws_lambda_layer_version.paho_mqtt.arn")
        if feedback.type == "EXTERNAL":
            if feedback.brokerConfig:
                bc = feedback.brokerConfig
                deployer.add_env("BROKER_URL", bc.broker_url).add_env("BROKER_PORT", str(bc.broker_port))
                deployer.add_env("BROKER_USERNAME", bc.broker_username).add_env("BROKER_PASSWORD", bc.broker_password)
                deployer.add_env("USE_TLS", str(bc.use_tls).lower())
        else:
            deployer.add_statement("Allow", ["iot:Publish"], ["*"])
            
        self.tf_blocks.append(deployer.generate())

    def _create_collector_lambda(self, ns):
        arns = list(set(t.hot_reader_arn for t in ns.resolved_twins))
        deployer = LambdaDeployer(f"{ns.name}_collector", COLLECTOR_PATH)
        deployer.add_statement("Allow", ["lambda:InvokeFunction"], arns)
        
        # Die Struktur, die in die Umgebungsvariable geladen wird
        # { "CombineToAuthbroker": [ { ... Parameter 1 ... }, { ... Parameter 2 ... } ] }
        params = {
            ns.name: []
        }
        
        for twin, strat in zip(ns.resolved_twins, ns.resolved_strategies):
            for i in strat.inputParameters:
                params[ns.name].append({
                    "name": i.name, 
                    "dataType": i.dataType, 
                    "strategy_name": strat.eventName,
                    "hot_reader_arn": twin.hot_reader_arn, 
                    "region": twin.region,
                    "workspace_id": twin.twinmaker_workspace_id,
                    "entity_id": i.id.split(".")[0] if "." in i.id else "",
                    "component_name": i.id.split(".")[1] if i.id.count(".") > 0 else "",
                    "property_name": i.id.split(".")[2] if i.id.count(".") > 1 else "",
                    **({"value": i.value} if i.value is not None else {})
                })
            
        deployer.add_env("PARAMETERS", json.dumps(params).replace('"', '\\"'))
        self.tf_blocks.append(deployer.generate())

    def _create_new_strategy_lambda(self, ns):
        deployer = LambdaDeployer(f"{ns.name}_strategy", ns.pathToCode)
        self.tf_blocks.append(deployer.generate())

    def _create_step_function(self, ns):
        name = ns.name
        self.tf_blocks.append(f"""
resource "aws_iam_role" "{name}_sf_role" {{
  name = "{name}-sf-role"
  assume_role_policy = jsonencode({{
    Version = "2012-10-17"
    Statement = [{{
      Effect = "Allow"
      Principal = {{ Service = "states.amazonaws.com" }}
      Action = "sts:AssumeRole"
    }}]
  }})
}}
resource "aws_iam_role_policy" "{name}_sf_policy" {{
  role = aws_iam_role.{name}_sf_role.id
  policy = jsonencode({{
    Version = "2012-10-17"
    Statement = [{{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.{name}_collector.arn, aws_lambda_function.{name}_strategy.arn, aws_lambda_function.{name}_feedback.arn]
    }}]
  }})
}}""")
        df = {
            "StartAt": "Collector",
            "States": {
                "Collector": {"Type": "Task", "Resource": f"${{aws_lambda_function.{name}_collector.arn}}", "ResultPath": "$.collectorResult", "Next": "Strategy"},
                "Strategy": {"Type": "Task", "Resource": f"${{aws_lambda_function.{name}_strategy.arn}}", "InputPath": "$.collectorResult", "ResultPath": "$.strategyResult", "Next": "Feedback"},
                "Feedback": {"Type": "Task", "Resource": f"${{aws_lambda_function.{name}_feedback.arn}}", "InputPath": "$", "End": True}
            }
        }
        self.tf_blocks.append(f'resource "aws_sfn_state_machine" "{name}_workflow" {{\n  name = "{name}-workflow"\n  role_arn = aws_iam_role.{name}_sf_role.arn\n  definition = "{json.dumps(df).replace('"', '\\"').replace("\n", "\\n")}"\n}}')

    def _create_workflow(self, ns):
        self._create_collector_lambda(ns)
        self._create_new_strategy_lambda(ns)
        self._create_feedback_lambda(ns)
        self._create_step_function(ns)

    def _create_ssm_parameters(self, new_strategies):
        ssm_map = {}
        for ns in new_strategies:
            for twin, strategy in zip(ns.resolved_twins, ns.resolved_strategies):
                p_name = f"{twin.ssm_registry_prefix}/{strategy.eventName}"
                if p_name not in ssm_map: ssm_map[p_name] = (twin.region.replace("-", "_"), [])
                ssm_map[p_name][1].append(f"aws_sfn_state_machine.{ns.name}_workflow.arn")
                
        for p_name, (alias, arns) in ssm_map.items():
            targets = ", ".join(f'{{address = {arn}}}' for arn in arns)
            res_name = p_name.replace("/", "_").strip("_")
            
            self.tf_blocks.append(f"""resource "aws_ssm_parameter" "{res_name}_registry" {{
  provider  = aws.{alias}
  name      = "{p_name}"
  type      = "String"
  overwrite = true
  value     = jsonencode({{targets = [{targets}]}})
}}""")