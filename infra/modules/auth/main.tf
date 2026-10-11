# Cognito user pool shared by the app and the website: email sign-up confirmed by an
# emailed code, optional TOTP multi-factor sign-in.

resource "aws_cognito_user_pool" "main" {
  name                     = var.name_prefix
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
  mfa_configuration        = "OPTIONAL"
  deletion_protection      = var.deletion_protection ? "ACTIVE" : "INACTIVE"
  user_pool_tier           = var.threat_protection ? "PLUS" : "ESSENTIALS"

  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length                   = 12
    require_lowercase                = true
    require_uppercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 3
  }

  software_token_mfa_configuration {
    enabled = true
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "Your Secure Captures code"
    email_message        = "Your Secure Captures verification code is {####}"
  }

  # Cognito's own email sender allows about 50 emails a day; move to SES before launch.
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  lambda_config {
    post_confirmation = var.post_confirmation_lambda_arn
  }

  dynamic "user_pool_add_ons" {
    for_each = var.threat_protection ? [1] : []
    content {
      advanced_security_mode = "ENFORCED"
    }
  }

  lifecycle {
    # Cognito does not allow schema changes after creation.
    ignore_changes = [schema]
  }
}

resource "aws_lambda_permission" "post_confirmation" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.post_confirmation_lambda_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

locals {
  # Public clients (no secret) using SRP, so passwords never cross the network.
  clients = {
    android = "${var.name_prefix}-android"
    web     = "${var.name_prefix}-web"
  }
}

resource "aws_cognito_user_pool_client" "this" {
  for_each     = local.clients
  name         = each.value
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret               = false
  explicit_auth_flows           = ["ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 30
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  read_attributes  = ["email", "email_verified"]
  write_attributes = ["email"]
}
