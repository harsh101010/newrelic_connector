variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "s3_to_newrelic_connector_lambda"
}

variable "s3_bucket" {
  description = "S3 bucket to store Lambda zip file and lb logs"
  type        = string
  default     = "kpp_lb_logs"
}

variable "s3_key" {
  description = "S3 key for the Lambda zip file"
  type        = string
  default     = "s3_to_newrelic_connector_lambda.zip"
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}
