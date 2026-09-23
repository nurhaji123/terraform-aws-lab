output "cw_alarm_name" {
  description = "Name of the CloudWatch CPU alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.alarm_name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.cpu_alarm_logger.function_name
}
