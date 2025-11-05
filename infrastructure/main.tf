terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "ap-south-1"
}

# ---------- 0. Random suffix ----------
resource "random_id" "suffix" {
  byte_length = 2
}

# ---------- 1. Frontend S3 Bucket ----------
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "kalyani-serverless-frontend-bucket-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Name = "serverless-frontend"
    Env  = "dev"
  }
}

resource "aws_s3_bucket_ownership_controls" "frontend_ownership" {
  bucket = aws_s3_bucket.frontend_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket                  = aws_s3_bucket.frontend_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend_site" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "frontend_bucket_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
    }]
  })

  depends_on = [
    aws_s3_bucket_public_access_block.frontend_public_access,
    aws_s3_bucket_ownership_controls.frontend_ownership
  ]
}

# upload HTML file
resource "aws_s3_object" "index_html" {
  bucket       = aws_s3_bucket.frontend_bucket.id
  key          = "index.html"
  source       = "${path.module}/../frontend/index.html"
  content_type = "text/html"

  depends_on = [
    aws_s3_bucket_policy.frontend_bucket_policy,
    aws_s3_bucket_ownership_controls.frontend_ownership
  ]
}

# ---------- 2. Lambda ----------
resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role_${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to read/write from the DynamoDB table
resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name = "lambda_dynamodb_policy_${random_id.suffix.hex}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.app_data_table.arn
      }
    ]
  })
}


resource "aws_lambda_function" "backend_function" {
  filename         = "${path.module}/../backend/lambda.zip"
  function_name    = "serverless-backend-${random_id.suffix.hex}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("${path.module}/../backend/lambda.zip")
}

# ---------- 3. API Gateway ----------
resource "aws_apigatewayv2_api" "api" {
  name          = "serverless-api-${random_id.suffix.hex}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_credentials = false
  }
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.backend_function.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Create route `/fetch`
resource "aws_apigatewayv2_route" "route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /fetch"
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "dev"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# ---------- DYNAMODB: minimal table for app data ----------
resource "aws_dynamodb_table" "app_data_table" {
  name         = "serverless-app-data-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "ServerlessAppData"
    Env  = "dev"
  }
}


# ---------- 4. Outputs ----------
output "api_endpoint" {
  value = "${aws_apigatewayv2_stage.stage.invoke_url}/fetch"
}

output "s3_website_endpoint" {
  value = aws_s3_bucket_website_configuration.frontend_site.website_endpoint
}

