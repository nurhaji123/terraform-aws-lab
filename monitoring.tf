# Build a ZIP archive containing the Lambda Python code.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_payload.zip"
}

# Trust policy allowing AWS Lambda to assume the execution role.
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Execution role used by the Lambda function.
resource "aws_iam_role" "lambda_execution" {
  name               = "tf-lambda-basic-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = {
    Name = "tf-lambda-basic-execution-role"
  }
}

# Attach AWS-managed permissions for writing Lambda logs to CloudWatch Logs.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create the Lambda function.
resource "aws_lambda_function" "cpu_alarm_logger" {
  function_name = "tf-cpu-alarm-logger"

  role    = aws_iam_role.lambda_execution.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  memory_size = 128
  timeout     = 30

  environment {
    variables = {
      INSTANCE_ID = aws_instance.web.id
    }
  }

  tags = {
    Name = "tf-cpu-alarm-logger"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution
  ]
}

# Monitor average EC2 CPU utilisation over a five-minute period.
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "tf-cpu-high-alarm"
  alarm_description   = "Alarm when CPU exceeds 50% for 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"

  evaluation_periods = 1
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = 300
  statistic          = "Average"
  threshold          = 50

  dimensions = {
    InstanceId = aws_instance.web.id
  }

  alarm_actions = [
    aws_lambda_function.cpu_alarm_logger.arn
  ]

  tags = {
    Name = "tf-cpu-high-alarm"
  }
}

# Allow CloudWatch Alarms to invoke the Lambda function.
resource "aws_lambda_permission" "allow_cloudwatch_alarm" {
  statement_id  = "AllowCloudWatchAlarmInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cpu_alarm_logger.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.cpu_high.arn
}
