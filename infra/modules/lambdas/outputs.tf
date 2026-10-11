output "api" {
  value = {
    function_name = module.api.function_name
    function_arn  = module.api.function_arn
    invoke_arn    = module.api.invoke_arn
  }
}

output "post_confirmation" {
  value = {
    function_name = module.post_confirmation.function_name
    function_arn  = module.post_confirmation.function_arn
  }
}
