from importlib.resources import path
import json
import os
import re
import shutil

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COLLECTOR_PATH = os.path.join(BASE_DIR, "lambda_functions", "collector")
FEEDBACK_PATH = os.path.join(BASE_DIR, "lambda_functions", "feedback")
PIPELINE_PATH = os.path.join(BASE_DIR, "lambda_functions", "pipeline")
TWIN_CONFIGS_MODULE = os.path.join(BASE_DIR, "lambda_functions", "twin_config.py")


def _terraform_path(path: str) -> str:
    return path.replace("\\", "/")

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
        env_block = "\n      ".join(f"{k} = {json.dumps(v)}" for k, v in self.env_vars.items())
        layers_line = f"layers = [{', '.join(self.layers)}]" if self.layers else ""
        source_dir = _terraform_path(self.source_dir)

        return f"""
data "archive_file" "{self.name}_zip" {{
  type        = "zip"
  source_dir  = "{source_dir}"
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

REQUIRED_TWIN_CONFIGS = (
    "config.json",
    "config_iot_devices.json",
    "config_events.json",
    "config_hierarchy.json",
)


def _twin_config_files(path: str) -> list[str]:
    """A single config file, or every *.json file directly inside a folder."""
    if os.path.isdir(path):
        files = sorted(
            os.path.join(path, name) for name in os.listdir(path)
            if name.endswith(".json") and os.path.isfile(os.path.join(path, name))
        )
        if not files:
            raise FileNotFoundError(f"Twin config folder contains no .json files: {path}")
        return files
    if not os.path.isfile(path):
        raise FileNotFoundError(f"Twin config not found: {path}")
    return [path]


class TerraformConfig:
    def __init__(self, fed_config, twin_configs: list[tuple[str, str]]):
        self.fed_config = fed_config
        self.twin_configs = twin_configs or []
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

    def _check_twin_configs(self):
        """Fail before packaging if a twin with a federation input lacks its configs.

        twin_configs.py reads the configs only at runtime, so a missing file would
        otherwise surface as a FileNotFoundError in the deployed Lambda.
        """
        if not self.twin_configs:
            print("Warning: no --twin_config given; strategy code cannot use twin_configs.py.")
            return
        shipped: dict[str, set[str]] = {}
        for twin, path in self.twin_configs:
            names = {os.path.basename(f) for f in _twin_config_files(path)}
            shipped.setdefault(twin, set()).update(names)
        missing = []
        for twin in sorted(t.name for t in self.fed_config.twins.values()):
            for name in REQUIRED_TWIN_CONFIGS:
                if name not in shipped.get(twin, set()):
                    missing.append(f"{twin}: {name}")
        unknown = sorted(set(shipped) - {t.name for t in self.fed_config.twins.values()})
        if unknown:
            missing.append("no federation input for --twin_config twin(s): " + ", ".join(unknown))
        if missing:
            raise ValueError("Incomplete twin configs:\n  " + "\n  ".join(missing))

    def generate(self, output_path: str):
        self._check_twin_configs()
        out_dir = os.path.dirname(os.path.abspath(output_path))
        os.makedirs(out_dir, exist_ok=True)
        self._create_providers()

        all_new_strategies = []
        for fed_twin in self.fed_config.fedTwinConfig.fedTwins:
            for new_strategy in fed_twin.newStrategies:
                all_new_strategies.append(new_strategy)

        if any(ns.feedback.type.upper() == "EXTERNAL" for ns in all_new_strategies):
            self._prepare_paho_layer(out_dir)

        for new_strategy in all_new_strategies:
            self._create_pipeline_lambda(new_strategy, out_dir)

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

    def _pipeline_source_dir(self, ns, output_dir: str) -> str:
        strategy_source = os.path.abspath(os.path.expanduser(ns.pathToCode))
        strategy_handler = os.path.join(strategy_source, "lambda_function.py")
        if not os.path.isfile(strategy_handler):
            raise FileNotFoundError(
                f"Strategy '{ns.name}' must contain a lambda_function.py file: {strategy_source}"
            )

        safe_name = re.sub(r"[^A-Za-z0-9_.-]", "_", ns.name)
        build_root = os.path.join(output_dir, ".build")
        build_dir = os.path.join(build_root, f"{safe_name}_pipeline")

        if os.path.exists(build_dir):
            shutil.rmtree(build_dir)
        os.makedirs(build_root, exist_ok=True)

        ignore = shutil.ignore_patterns("__pycache__", "*.pyc", "*.pyo", "*.zip", ".venv", "venv")
        shutil.copytree(PIPELINE_PATH, build_dir, ignore=ignore)
        shutil.copytree(COLLECTOR_PATH, os.path.join(build_dir, "collector"), ignore=ignore)
        shutil.copytree(FEEDBACK_PATH, os.path.join(build_dir, "feedback"), ignore=ignore)
        shutil.copytree(strategy_source, os.path.join(build_dir, "strategy"), ignore=ignore)
        shutil.copy2(TWIN_CONFIGS_MODULE, os.path.join(build_dir, "twin_configs.py"))
        for twin, path in self.twin_configs:
            target = os.path.join(build_dir, "twins", twin)
            os.makedirs(target, exist_ok=True)
            for config_file in _twin_config_files(path):
                shutil.copy2(config_file, os.path.join(target, os.path.basename(config_file)))
        for twin in self.fed_config.twins.values():
            target = os.path.join(build_dir, "twins", twin.name)
            os.makedirs(target, exist_ok=True)
            with open(os.path.join(target, "hot_reader.json"), "w", encoding="utf-8") as f:
                json.dump({
                    "hot_reader_arn": twin.hot_reader_arn,
                    "workspace_id": twin.twinmaker_workspace_id,
                    "region": twin.region,
                }, f)
        
        relative_build_dir = _terraform_path(os.path.relpath(build_dir, output_dir))
        return f"${{path.module}}/{relative_build_dir}"

    def _create_pipeline_lambda(self, ns, output_dir: str):
        arns = sorted(set(t.hot_reader_arn for t in self.fed_config.twins.values()))
        source_dir = self._pipeline_source_dir(ns, output_dir)
        deployer = LambdaDeployer(f"{ns.name}_pipeline", source_dir, timeout=90)
        deployer.add_statement("Allow", ["lambda:InvokeFunction"], arns)

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

        feedback = ns.feedback
        feedback_type = feedback.type.upper()
        deployer.add_env("PARAMETERS", json.dumps(params))
        deployer.add_env("FEEDBACK_TYPE", feedback_type)
        deployer.add_env("FEEDBACK_TOPIC", feedback.topic)

        if feedback_type == "EXTERNAL":
            if not feedback.brokerConfig:
                raise ValueError(f"External feedback for '{ns.name}' requires brokerConfig")
            bc = feedback.brokerConfig
            deployer.add_env("BROKER_URL", bc.broker_url)
            deployer.add_env("BROKER_PORT", str(bc.broker_port))
            deployer.add_env("BROKER_USERNAME", bc.broker_username)
            deployer.add_env("BROKER_PASSWORD", bc.broker_password)
            deployer.add_env("USE_TLS", str(bc.use_tls).lower())
            deployer.add_layer("aws_lambda_layer_version.paho_mqtt.arn")
        elif feedback_type == "INTERNAL":
            deployer.add_statement("Allow", ["iot:Publish"], ["*"])
        else:
            raise ValueError(f"Unsupported feedback type '{feedback.type}' for '{ns.name}'")

        self.tf_blocks.append(deployer.generate())

    def _create_ssm_parameters(self, new_strategies):
        ssm_map = {}
        for ns in new_strategies:
            for twin, strategy in zip(ns.resolved_twins, ns.resolved_strategies):
                p_name = f"{twin.ssm_registry_prefix}/{strategy.eventName}"
                if p_name not in ssm_map: ssm_map[p_name] = (twin.region.replace("-", "_"), [])
                ssm_map[p_name][1].append(f"aws_lambda_function.{ns.name}_pipeline.arn")

        for p_name, (alias, arns) in ssm_map.items():
            targets = ", ".join(f'{{type = "lambda", address = {arn}}}' for arn in arns)
            res_name = p_name.replace("/", "_").strip("_")
            
            self.tf_blocks.append(f"""resource "aws_ssm_parameter" "{res_name}_registry" {{
  provider  = aws.{alias}
  name      = "{p_name}"
  type      = "String"
  overwrite = true
  value     = jsonencode({{targets = [{targets}]}})
}}""")