provider "aws" {
  region = "eu-north-1"
}

resource "aws_s3_bucket" "newrelic_lambda_bucket" {
  bucket = var.s3_bucket  # Make sure this name is unique
  acl    = "private"
  
  tags = {
    Name        = "LBLogs"    
  }
}

resource "aws_s3_bucket_object" "lambda_zip" {
  bucket = aws_s3_bucket.newrelic_lambda_bucket.bucket
  key    = var.s3_key
  source =  "../s3_to_newrelic_connector_lambda.zip" 
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role_for_newrelic_injection"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3FullAccessRole"
}



resource "aws_lambda_function" "lambda" {
  function_name = var.lambda_function_name
  s3_bucket     = aws_s3_bucket.newrelic_lambda_bucket.bucket
  s3_key        = aws_s3_bucket_object.lambda_zip.key
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 20
  environment {
    variables = {
      LICENSE_KEY: "eu01xx0a62e5c71fe0fe906eb8140430FFFFNRAL"
      LOG_TYPE: "alb"
    }    
  }
}

# Add S3 bucket notification to trigger Lambda
resource "aws_s3_bucket_notification" "example_notification" {
  bucket = aws_s3_bucket.newrelic_lambda_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "logs/"
  }

  depends_on = [aws_lambda_permission.example_permission]
}

# Give S3 permission to invoke the Lambda function
resource "aws_lambda_permission" "example_permission" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.newrelic_lambda_bucket.arn
}
