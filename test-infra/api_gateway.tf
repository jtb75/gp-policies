# =============================================================================
# API Gateway — Test fixtures for authorization CCR
# =============================================================================

# Triggers: aws_apigateway_no_authorization (method with AuthorizationType NONE)
resource "aws_api_gateway_rest_api" "test_no_auth" {
  name = "jtb75-test-no-auth-api"
  tags = {
    Purpose = "test-ccr"
  }
}

resource "aws_api_gateway_resource" "test_no_auth" {
  rest_api_id = aws_api_gateway_rest_api.test_no_auth.id
  parent_id   = aws_api_gateway_rest_api.test_no_auth.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_no_auth" {
  rest_api_id   = aws_api_gateway_rest_api.test_no_auth.id
  resource_id   = aws_api_gateway_resource.test_no_auth.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_no_auth" {
  rest_api_id = aws_api_gateway_rest_api.test_no_auth.id
  resource_id = aws_api_gateway_resource.test_no_auth.id
  http_method = aws_api_gateway_method.test_no_auth.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# SKIP: API Gateway with authentication:kochid exemption tag
resource "aws_api_gateway_rest_api" "test_kochid_exempt" {
  name = "jtb75-test-kochid-exempt-api"
  tags = {
    Purpose        = "test-ccr"
    authentication = "kochid"
  }
}

resource "aws_api_gateway_resource" "test_kochid_exempt" {
  rest_api_id = aws_api_gateway_rest_api.test_kochid_exempt.id
  parent_id   = aws_api_gateway_rest_api.test_kochid_exempt.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_kochid_exempt" {
  rest_api_id   = aws_api_gateway_rest_api.test_kochid_exempt.id
  resource_id   = aws_api_gateway_resource.test_kochid_exempt.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test_kochid_exempt" {
  rest_api_id = aws_api_gateway_rest_api.test_kochid_exempt.id
  resource_id = aws_api_gateway_resource.test_kochid_exempt.id
  http_method = aws_api_gateway_method.test_kochid_exempt.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# PASS: API Gateway with IAM authorization
resource "aws_api_gateway_rest_api" "test_iam_auth" {
  name = "jtb75-test-iam-auth-api"
  tags = {
    Purpose = "test-ccr"
  }
}

resource "aws_api_gateway_resource" "test_iam_auth" {
  rest_api_id = aws_api_gateway_rest_api.test_iam_auth.id
  parent_id   = aws_api_gateway_rest_api.test_iam_auth.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test_iam_auth" {
  rest_api_id   = aws_api_gateway_rest_api.test_iam_auth.id
  resource_id   = aws_api_gateway_resource.test_iam_auth.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "test_iam_auth" {
  rest_api_id = aws_api_gateway_rest_api.test_iam_auth.id
  resource_id = aws_api_gateway_resource.test_iam_auth.id
  http_method = aws_api_gateway_method.test_iam_auth.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}
