provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"
}


resource "aws_lambda_layer_version" "paho_mqtt" {
  filename            = "paho_layer.zip"
  layer_name          = "paho_mqtt_layer"
  compatible_runtimes = ["python3.13"]
}


data "archive_file" "ConsumptionStrategy_collector_zip" {
  type        = "zip"
  source_dir  = "/mnt/c/Users/marco/FedSysML/src/lambda_functions/collector"
  output_path = "${path.module}/ConsumptionStrategy_collector_payload.zip"
}

resource "aws_iam_role" "ConsumptionStrategy_collector_role" {
  name = "ConsumptionStrategy_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ConsumptionStrategy_collector_policy" {
  role = aws_iam_role.ConsumptionStrategy_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "ConsumptionStrategy_collector" {
  filename         = data.archive_file.ConsumptionStrategy_collector_zip.output_path
  source_code_hash = data.archive_file.ConsumptionStrategy_collector_zip.output_base64sha256
  function_name    = "ConsumptionStrategy_collector"
  role             = aws_iam_role.ConsumptionStrategy_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"ConsumptionStrategy\": [{\"name\": \"generatedPower\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"production\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"QWB3zi3nv8UNdtvw8Fbkk8\", \"component_name\": \"PVconst_component\", \"property_name\": \"generatedPower\", \"value\": 50.0}, {\"name\": \"chargeValue\", \"dataType\": \"INTEGER\", \"strategy_name\": \"status\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"4udMBA6jAnnRf33MNHHP9P\", \"component_name\": \"p16\", \"property_name\": \"charges\"}]}"
    }
  }
}


data "archive_file" "ConsumptionStrategy_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/input/sysml/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/ConsumptionStrategy_strategy_payload.zip"
}

resource "aws_iam_role" "ConsumptionStrategy_strategy_role" {
  name = "ConsumptionStrategy_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ConsumptionStrategy_strategy_policy" {
  role = aws_iam_role.ConsumptionStrategy_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "ConsumptionStrategy_strategy" {
  filename         = data.archive_file.ConsumptionStrategy_strategy_zip.output_path
  source_code_hash = data.archive_file.ConsumptionStrategy_strategy_zip.output_base64sha256
  function_name    = "ConsumptionStrategy_strategy"
  role             = aws_iam_role.ConsumptionStrategy_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "ConsumptionStrategy_feedback_zip" {
  type        = "zip"
  source_dir  = "/mnt/c/Users/marco/FedSysML/src/lambda_functions/feedback"
  output_path = "${path.module}/ConsumptionStrategy_feedback_payload.zip"
}

resource "aws_iam_role" "ConsumptionStrategy_feedback_role" {
  name = "ConsumptionStrategy_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ConsumptionStrategy_feedback_policy" {
  role = aws_iam_role.ConsumptionStrategy_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["iot:Publish"], "Resource": ["*"]}]
  })
}

resource "aws_lambda_function" "ConsumptionStrategy_feedback" {
  filename         = data.archive_file.ConsumptionStrategy_feedback_zip.output_path
  source_code_hash = data.archive_file.ConsumptionStrategy_feedback_zip.output_base64sha256
  function_name    = "ConsumptionStrategy_feedback"
  role             = aws_iam_role.ConsumptionStrategy_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "INTERNAL"
      FEEDBACK_TOPIC = "Battery/iot-data"
    }
  }
}


resource "aws_iam_role" "ConsumptionStrategy_sf_role" {
  name = "ConsumptionStrategy-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "ConsumptionStrategy_sf_policy" {
  role = aws_iam_role.ConsumptionStrategy_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.ConsumptionStrategy_collector.arn, aws_lambda_function.ConsumptionStrategy_strategy.arn, aws_lambda_function.ConsumptionStrategy_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "ConsumptionStrategy_workflow" {
  name = "ConsumptionStrategy-workflow"
  role_arn = aws_iam_role.ConsumptionStrategy_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.ConsumptionStrategy_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.ConsumptionStrategy_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.ConsumptionStrategy_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}

resource "aws_ssm_parameter" "PV_event-registry_production_registry" {
  provider  = aws.eu_central_1
  name      = "/PV/event-registry/production"
  type      = "String"
  overwrite = true
  value     = jsonencode({targets = [{address = aws_sfn_state_machine.ConsumptionStrategy_workflow.arn}]})
}

resource "aws_ssm_parameter" "Battery_event-registry_status_registry" {
  provider  = aws.eu_central_1
  name      = "/Battery/event-registry/status"
  type      = "String"
  overwrite = true
  value     = jsonencode({targets = [{address = aws_sfn_state_machine.ConsumptionStrategy_workflow.arn}]})
}