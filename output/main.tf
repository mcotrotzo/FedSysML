provider "aws" {
  alias  = "eu_central_1"
  region = "eu-central-1"
}


resource "aws_lambda_layer_version" "paho_mqtt" {
  filename            = "paho_layer.zip"
  layer_name          = "paho_mqtt_layer"
  compatible_runtimes = ["python3.13"]
}


data "archive_file" "CombineAllInternal_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/CombineAllInternal_collector_payload.zip"
}

resource "aws_iam_role" "CombineAllInternal_collector_role" {
  name = "CombineAllInternal_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllInternal_collector_policy" {
  role = aws_iam_role.CombineAllInternal_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "CombineAllInternal_collector" {
  filename         = data.archive_file.CombineAllInternal_collector_zip.output_path
  source_code_hash = data.archive_file.CombineAllInternal_collector_zip.output_base64sha256
  function_name    = "CombineAllInternal_collector"
  role             = aws_iam_role.CombineAllInternal_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"CombineAllInternal\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"pV1\", \"property_name\": \"output\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"PVconst_component\", \"property_name\": \"peakThreshold\", \"value\": 8000.0}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"temperature\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"currentCapacity\"}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"Z4nLdDKudAfc4RAAXxJDLA\", \"component_name\": \"p12\", \"property_name\": \"consumption\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"MKjsFDqWjCxJmcAvj9du6f\", \"component_name\": \"p13\", \"property_name\": \"power\"}]}"
    }
  }
}


data "archive_file" "CombineAllInternal_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/CombineAllInternal_strategy_payload.zip"
}

resource "aws_iam_role" "CombineAllInternal_strategy_role" {
  name = "CombineAllInternal_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllInternal_strategy_policy" {
  role = aws_iam_role.CombineAllInternal_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombineAllInternal_strategy" {
  filename         = data.archive_file.CombineAllInternal_strategy_zip.output_path
  source_code_hash = data.archive_file.CombineAllInternal_strategy_zip.output_base64sha256
  function_name    = "CombineAllInternal_strategy"
  role             = aws_iam_role.CombineAllInternal_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "CombineAllInternal_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/CombineAllInternal_feedback_payload.zip"
}

resource "aws_iam_role" "CombineAllInternal_feedback_role" {
  name = "CombineAllInternal_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllInternal_feedback_policy" {
  role = aws_iam_role.CombineAllInternal_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["iot:Publish"], "Resource": ["*"]}]
  })
}

resource "aws_lambda_function" "CombineAllInternal_feedback" {
  filename         = data.archive_file.CombineAllInternal_feedback_zip.output_path
  source_code_hash = data.archive_file.CombineAllInternal_feedback_zip.output_base64sha256
  function_name    = "CombineAllInternal_feedback"
  role             = aws_iam_role.CombineAllInternal_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "INTERNAL"
      FEEDBACK_TOPIC = "EXTERN_TPIC"
    }
  }
}


resource "aws_iam_role" "CombineAllInternal_sf_role" {
  name = "CombineAllInternal-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "CombineAllInternal_sf_policy" {
  role = aws_iam_role.CombineAllInternal_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.CombineAllInternal_collector.arn, aws_lambda_function.CombineAllInternal_strategy.arn, aws_lambda_function.CombineAllInternal_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "CombineAllInternal_workflow" {
  name = "CombineAllInternal-workflow"
  role_arn = aws_iam_role.CombineAllInternal_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllInternal_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllInternal_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllInternal_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}


data "archive_file" "CombineAllExternal_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/CombineAllExternal_collector_payload.zip"
}

resource "aws_iam_role" "CombineAllExternal_collector_role" {
  name = "CombineAllExternal_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllExternal_collector_policy" {
  role = aws_iam_role.CombineAllExternal_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "CombineAllExternal_collector" {
  filename         = data.archive_file.CombineAllExternal_collector_zip.output_path
  source_code_hash = data.archive_file.CombineAllExternal_collector_zip.output_base64sha256
  function_name    = "CombineAllExternal_collector"
  role             = aws_iam_role.CombineAllExternal_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"CombineAllExternal\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"pV1\", \"property_name\": \"output\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"PVconst_component\", \"property_name\": \"peakThreshold\", \"value\": 8000.0}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"temperature\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"currentCapacity\"}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"Z4nLdDKudAfc4RAAXxJDLA\", \"component_name\": \"p12\", \"property_name\": \"consumption\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"MKjsFDqWjCxJmcAvj9du6f\", \"component_name\": \"p13\", \"property_name\": \"power\"}]}"
    }
  }
}


data "archive_file" "CombineAllExternal_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/CombineAllExternal_strategy_payload.zip"
}

resource "aws_iam_role" "CombineAllExternal_strategy_role" {
  name = "CombineAllExternal_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllExternal_strategy_policy" {
  role = aws_iam_role.CombineAllExternal_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombineAllExternal_strategy" {
  filename         = data.archive_file.CombineAllExternal_strategy_zip.output_path
  source_code_hash = data.archive_file.CombineAllExternal_strategy_zip.output_base64sha256
  function_name    = "CombineAllExternal_strategy"
  role             = aws_iam_role.CombineAllExternal_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "CombineAllExternal_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/CombineAllExternal_feedback_payload.zip"
}

resource "aws_iam_role" "CombineAllExternal_feedback_role" {
  name = "CombineAllExternal_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineAllExternal_feedback_policy" {
  role = aws_iam_role.CombineAllExternal_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombineAllExternal_feedback" {
  filename         = data.archive_file.CombineAllExternal_feedback_zip.output_path
  source_code_hash = data.archive_file.CombineAllExternal_feedback_zip.output_base64sha256
  function_name    = "CombineAllExternal_feedback"
  role             = aws_iam_role.CombineAllExternal_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "EXTERNAL"
      FEEDBACK_TOPIC = "unAuthBroker/topics/peakAlert"
      BROKER_URL = "broker.hivemq.com"
      BROKER_PORT = "1883"
      BROKER_USERNAME = ""
      BROKER_PASSWORD = ""
      USE_TLS = "false"
    }
  }
}


resource "aws_iam_role" "CombineAllExternal_sf_role" {
  name = "CombineAllExternal-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "CombineAllExternal_sf_policy" {
  role = aws_iam_role.CombineAllExternal_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.CombineAllExternal_collector.arn, aws_lambda_function.CombineAllExternal_strategy.arn, aws_lambda_function.CombineAllExternal_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "CombineAllExternal_workflow" {
  name = "CombineAllExternal-workflow"
  role_arn = aws_iam_role.CombineAllExternal_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllExternal_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllExternal_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineAllExternal_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}


data "archive_file" "CombinePVBattery_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/CombinePVBattery_collector_payload.zip"
}

resource "aws_iam_role" "CombinePVBattery_collector_role" {
  name = "CombinePVBattery_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVBattery_collector_policy" {
  role = aws_iam_role.CombinePVBattery_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "CombinePVBattery_collector" {
  filename         = data.archive_file.CombinePVBattery_collector_zip.output_path
  source_code_hash = data.archive_file.CombinePVBattery_collector_zip.output_base64sha256
  function_name    = "CombinePVBattery_collector"
  role             = aws_iam_role.CombinePVBattery_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"CombinePVBattery\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"pV1\", \"property_name\": \"output\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"PVconst_component\", \"property_name\": \"peakThreshold\", \"value\": 8000.0}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"temperature\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"currentCapacity\"}]}"
    }
  }
}


data "archive_file" "CombinePVBattery_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/CombinePVBattery_strategy_payload.zip"
}

resource "aws_iam_role" "CombinePVBattery_strategy_role" {
  name = "CombinePVBattery_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVBattery_strategy_policy" {
  role = aws_iam_role.CombinePVBattery_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombinePVBattery_strategy" {
  filename         = data.archive_file.CombinePVBattery_strategy_zip.output_path
  source_code_hash = data.archive_file.CombinePVBattery_strategy_zip.output_base64sha256
  function_name    = "CombinePVBattery_strategy"
  role             = aws_iam_role.CombinePVBattery_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "CombinePVBattery_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/CombinePVBattery_feedback_payload.zip"
}

resource "aws_iam_role" "CombinePVBattery_feedback_role" {
  name = "CombinePVBattery_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVBattery_feedback_policy" {
  role = aws_iam_role.CombinePVBattery_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombinePVBattery_feedback" {
  filename         = data.archive_file.CombinePVBattery_feedback_zip.output_path
  source_code_hash = data.archive_file.CombinePVBattery_feedback_zip.output_base64sha256
  function_name    = "CombinePVBattery_feedback"
  role             = aws_iam_role.CombinePVBattery_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "EXTERNAL"
      FEEDBACK_TOPIC = "unAuthBroker/topics/peakAlert"
      BROKER_URL = "broker.hivemq.com"
      BROKER_PORT = "1883"
      BROKER_USERNAME = ""
      BROKER_PASSWORD = ""
      USE_TLS = "false"
    }
  }
}


resource "aws_iam_role" "CombinePVBattery_sf_role" {
  name = "CombinePVBattery-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "CombinePVBattery_sf_policy" {
  role = aws_iam_role.CombinePVBattery_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.CombinePVBattery_collector.arn, aws_lambda_function.CombinePVBattery_strategy.arn, aws_lambda_function.CombinePVBattery_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "CombinePVBattery_workflow" {
  name = "CombinePVBattery-workflow"
  role_arn = aws_iam_role.CombinePVBattery_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVBattery_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVBattery_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVBattery_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}


data "archive_file" "CombinePVGrid_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/CombinePVGrid_collector_payload.zip"
}

resource "aws_iam_role" "CombinePVGrid_collector_role" {
  name = "CombinePVGrid_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVGrid_collector_policy" {
  role = aws_iam_role.CombinePVGrid_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader"]}]
  })
}

resource "aws_lambda_function" "CombinePVGrid_collector" {
  filename         = data.archive_file.CombinePVGrid_collector_zip.output_path
  source_code_hash = data.archive_file.CombinePVGrid_collector_zip.output_base64sha256
  function_name    = "CombinePVGrid_collector"
  role             = aws_iam_role.CombinePVGrid_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"CombinePVGrid\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"pV1\", \"property_name\": \"output\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"peakProduction\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:PV-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"PV-twinmaker\", \"entity_id\": \"NZrw6C5K5Edpk57vfJk96W\", \"component_name\": \"PVconst_component\", \"property_name\": \"peakThreshold\", \"value\": 8000.0}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"Z4nLdDKudAfc4RAAXxJDLA\", \"component_name\": \"p12\", \"property_name\": \"consumption\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"MKjsFDqWjCxJmcAvj9du6f\", \"component_name\": \"p13\", \"property_name\": \"power\"}]}"
    }
  }
}


data "archive_file" "CombinePVGrid_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/CombinePVGrid_strategy_payload.zip"
}

resource "aws_iam_role" "CombinePVGrid_strategy_role" {
  name = "CombinePVGrid_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVGrid_strategy_policy" {
  role = aws_iam_role.CombinePVGrid_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombinePVGrid_strategy" {
  filename         = data.archive_file.CombinePVGrid_strategy_zip.output_path
  source_code_hash = data.archive_file.CombinePVGrid_strategy_zip.output_base64sha256
  function_name    = "CombinePVGrid_strategy"
  role             = aws_iam_role.CombinePVGrid_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "CombinePVGrid_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/CombinePVGrid_feedback_payload.zip"
}

resource "aws_iam_role" "CombinePVGrid_feedback_role" {
  name = "CombinePVGrid_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombinePVGrid_feedback_policy" {
  role = aws_iam_role.CombinePVGrid_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombinePVGrid_feedback" {
  filename         = data.archive_file.CombinePVGrid_feedback_zip.output_path
  source_code_hash = data.archive_file.CombinePVGrid_feedback_zip.output_base64sha256
  function_name    = "CombinePVGrid_feedback"
  role             = aws_iam_role.CombinePVGrid_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "EXTERNAL"
      FEEDBACK_TOPIC = "unAuthBroker/topics/peakAlert"
      BROKER_URL = "broker.hivemq.com"
      BROKER_PORT = "1883"
      BROKER_USERNAME = ""
      BROKER_PASSWORD = ""
      USE_TLS = "false"
    }
  }
}


resource "aws_iam_role" "CombinePVGrid_sf_role" {
  name = "CombinePVGrid-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "CombinePVGrid_sf_policy" {
  role = aws_iam_role.CombinePVGrid_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.CombinePVGrid_collector.arn, aws_lambda_function.CombinePVGrid_strategy.arn, aws_lambda_function.CombinePVGrid_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "CombinePVGrid_workflow" {
  name = "CombinePVGrid-workflow"
  role_arn = aws_iam_role.CombinePVGrid_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVGrid_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVGrid_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombinePVGrid_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}


data "archive_file" "SingleStrategyPass_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/SingleStrategyPass_collector_payload.zip"
}

resource "aws_iam_role" "SingleStrategyPass_collector_role" {
  name = "SingleStrategyPass_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "SingleStrategyPass_collector_policy" {
  role = aws_iam_role.SingleStrategyPass_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "SingleStrategyPass_collector" {
  filename         = data.archive_file.SingleStrategyPass_collector_zip.output_path
  source_code_hash = data.archive_file.SingleStrategyPass_collector_zip.output_base64sha256
  function_name    = "SingleStrategyPass_collector"
  role             = aws_iam_role.SingleStrategyPass_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"SingleStrategyPass\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"temperature\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"currentCapacity\"}]}"
    }
  }
}


data "archive_file" "SingleStrategyPass_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/SingleStrategyPass_strategy_payload.zip"
}

resource "aws_iam_role" "SingleStrategyPass_strategy_role" {
  name = "SingleStrategyPass_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "SingleStrategyPass_strategy_policy" {
  role = aws_iam_role.SingleStrategyPass_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "SingleStrategyPass_strategy" {
  filename         = data.archive_file.SingleStrategyPass_strategy_zip.output_path
  source_code_hash = data.archive_file.SingleStrategyPass_strategy_zip.output_base64sha256
  function_name    = "SingleStrategyPass_strategy"
  role             = aws_iam_role.SingleStrategyPass_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "SingleStrategyPass_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/SingleStrategyPass_feedback_payload.zip"
}

resource "aws_iam_role" "SingleStrategyPass_feedback_role" {
  name = "SingleStrategyPass_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "SingleStrategyPass_feedback_policy" {
  role = aws_iam_role.SingleStrategyPass_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["iot:Publish"], "Resource": ["*"]}]
  })
}

resource "aws_lambda_function" "SingleStrategyPass_feedback" {
  filename         = data.archive_file.SingleStrategyPass_feedback_zip.output_path
  source_code_hash = data.archive_file.SingleStrategyPass_feedback_zip.output_base64sha256
  function_name    = "SingleStrategyPass_feedback"
  role             = aws_iam_role.SingleStrategyPass_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "INTERNAL"
      FEEDBACK_TOPIC = "EXTERN_TPIC"
    }
  }
}


resource "aws_iam_role" "SingleStrategyPass_sf_role" {
  name = "SingleStrategyPass-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "SingleStrategyPass_sf_policy" {
  role = aws_iam_role.SingleStrategyPass_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.SingleStrategyPass_collector.arn, aws_lambda_function.SingleStrategyPass_strategy.arn, aws_lambda_function.SingleStrategyPass_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "SingleStrategyPass_workflow" {
  name = "SingleStrategyPass-workflow"
  role_arn = aws_iam_role.SingleStrategyPass_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.SingleStrategyPass_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.SingleStrategyPass_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.SingleStrategyPass_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}


data "archive_file" "CombineToAuthbroker_collector_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/collector"
  output_path = "${path.module}/CombineToAuthbroker_collector_payload.zip"
}

resource "aws_iam_role" "CombineToAuthbroker_collector_role" {
  name = "CombineToAuthbroker_collector-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineToAuthbroker_collector_policy" {
  role = aws_iam_role.CombineToAuthbroker_collector_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}, {"Effect": "Allow", "Action": ["lambda:InvokeFunction"], "Resource": ["arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader", "arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader"]}]
  })
}

resource "aws_lambda_function" "CombineToAuthbroker_collector" {
  filename         = data.archive_file.CombineToAuthbroker_collector_zip.output_path
  source_code_hash = data.archive_file.CombineToAuthbroker_collector_zip.output_base64sha256
  function_name    = "CombineToAuthbroker_collector"
  role             = aws_iam_role.CombineToAuthbroker_collector_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      PARAMETERS = "{\"CombineToAuthbroker\": [{\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"temperature\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overheatAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:Battery-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"Battery-twinmaker\", \"entity_id\": \"Yg5PFZKrNUtE8t8KGqQPGS\", \"component_name\": \"p16\", \"property_name\": \"currentCapacity\"}, {\"name\": \"test1\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"Z4nLdDKudAfc4RAAXxJDLA\", \"component_name\": \"p12\", \"property_name\": \"consumption\"}, {\"name\": \"test2\", \"dataType\": \"DOUBLE\", \"strategy_name\": \"overloadAlert\", \"hot_reader_arn\": \"arn:aws:lambda:eu-central-1:717556240325:function:MicroGrid-hot-reader\", \"region\": \"eu-central-1\", \"workspace_id\": \"MicroGrid-twinmaker\", \"entity_id\": \"MKjsFDqWjCxJmcAvj9du6f\", \"component_name\": \"p13\", \"property_name\": \"power\"}]}"
    }
  }
}


data "archive_file" "CombineToAuthbroker_strategy_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/testLambdaFunctions/fedTwinCombinedStrategy"
  output_path = "${path.module}/CombineToAuthbroker_strategy_payload.zip"
}

resource "aws_iam_role" "CombineToAuthbroker_strategy_role" {
  name = "CombineToAuthbroker_strategy-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineToAuthbroker_strategy_policy" {
  role = aws_iam_role.CombineToAuthbroker_strategy_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombineToAuthbroker_strategy" {
  filename         = data.archive_file.CombineToAuthbroker_strategy_zip.output_path
  source_code_hash = data.archive_file.CombineToAuthbroker_strategy_zip.output_base64sha256
  function_name    = "CombineToAuthbroker_strategy"
  role             = aws_iam_role.CombineToAuthbroker_strategy_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  

  environment {
    variables = {
      
    }
  }
}


data "archive_file" "CombineToAuthbroker_feedback_zip" {
  type        = "zip"
  source_dir  = "/home/marcocotrotzo/PycharmProjects/SymlCOnv/src/lambda_functions/feedback"
  output_path = "${path.module}/CombineToAuthbroker_feedback_payload.zip"
}

resource "aws_iam_role" "CombineToAuthbroker_feedback_role" {
  name = "CombineToAuthbroker_feedback-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "CombineToAuthbroker_feedback_policy" {
  role = aws_iam_role.CombineToAuthbroker_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{"Effect": "Allow", "Action": ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], "Resource": "*"}]
  })
}

resource "aws_lambda_function" "CombineToAuthbroker_feedback" {
  filename         = data.archive_file.CombineToAuthbroker_feedback_zip.output_path
  source_code_hash = data.archive_file.CombineToAuthbroker_feedback_zip.output_base64sha256
  function_name    = "CombineToAuthbroker_feedback"
  role             = aws_iam_role.CombineToAuthbroker_feedback_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.13"
  timeout          = 30
  layers = [aws_lambda_layer_version.paho_mqtt.arn]

  environment {
    variables = {
      FEEDBACK_TYPE = "EXTERNAL"
      FEEDBACK_TOPIC = "authBroker/topics/alerts"
      BROKER_URL = "cc673a1ab883421dbfcd225d0e26e925.s1.eu.hivemq.cloud"
      BROKER_PORT = "8883"
      BROKER_USERNAME = "Test12345678"
      BROKER_PASSWORD = "Test12345678"
      USE_TLS = "true"
    }
  }
}


resource "aws_iam_role" "CombineToAuthbroker_sf_role" {
  name = "CombineToAuthbroker-sf-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "states.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_role_policy" "CombineToAuthbroker_sf_policy" {
  role = aws_iam_role.CombineToAuthbroker_sf_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [aws_lambda_function.CombineToAuthbroker_collector.arn, aws_lambda_function.CombineToAuthbroker_strategy.arn, aws_lambda_function.CombineToAuthbroker_feedback.arn]
    }]
  })
}

resource "aws_sfn_state_machine" "CombineToAuthbroker_workflow" {
  name = "CombineToAuthbroker-workflow"
  role_arn = aws_iam_role.CombineToAuthbroker_sf_role.arn
  definition = "{\"StartAt\": \"Collector\", \"States\": {\"Collector\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineToAuthbroker_collector.arn}\", \"ResultPath\": \"$.collectorResult\", \"Next\": \"Strategy\"}, \"Strategy\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineToAuthbroker_strategy.arn}\", \"InputPath\": \"$.collectorResult\", \"ResultPath\": \"$.strategyResult\", \"Next\": \"Feedback\"}, \"Feedback\": {\"Type\": \"Task\", \"Resource\": \"${aws_lambda_function.CombineToAuthbroker_feedback.arn}\", \"InputPath\": \"$\", \"End\": true}}}"
}

resource "aws_ssm_parameter" "PV_event-registry_peakProduction_registry" {
  provider  = aws.eu_central_1
  name      = "/PV/event-registry/peakProduction"
  type      = "String"
  overwrite = true
  value     = jsonencode({targets = [{address = aws_sfn_state_machine.CombineAllInternal_workflow.arn}, {address = aws_sfn_state_machine.CombineAllExternal_workflow.arn}, {address = aws_sfn_state_machine.CombinePVBattery_workflow.arn}, {address = aws_sfn_state_machine.CombinePVGrid_workflow.arn}]})
}

resource "aws_ssm_parameter" "Battery_event-registry_overheatAlert_registry" {
  provider  = aws.eu_central_1
  name      = "/Battery/event-registry/overheatAlert"
  type      = "String"
  overwrite = true
  value     = jsonencode({targets = [{address = aws_sfn_state_machine.CombineAllInternal_workflow.arn}, {address = aws_sfn_state_machine.CombineAllExternal_workflow.arn}, {address = aws_sfn_state_machine.CombinePVBattery_workflow.arn}, {address = aws_sfn_state_machine.SingleStrategyPass_workflow.arn}, {address = aws_sfn_state_machine.CombineToAuthbroker_workflow.arn}]})
}

resource "aws_ssm_parameter" "MicroGrid_event-registry_overloadAlert_registry" {
  provider  = aws.eu_central_1
  name      = "/MicroGrid/event-registry/overloadAlert"
  type      = "String"
  overwrite = true
  value     = jsonencode({targets = [{address = aws_sfn_state_machine.CombineAllInternal_workflow.arn}, {address = aws_sfn_state_machine.CombineAllExternal_workflow.arn}, {address = aws_sfn_state_machine.CombinePVGrid_workflow.arn}, {address = aws_sfn_state_machine.CombineToAuthbroker_workflow.arn}]})
}