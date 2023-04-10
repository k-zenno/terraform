####################
# Cloudwatch Log
####################
#コンテナ用ログ
resource "aws_cloudwatch_log_group" "Container_Log" {
  name = "Container_Log"

  retention_in_days = "7" 
}

#コンテナビルド時ログ
resource "aws_cloudwatch_log_group" "fargate-build" {
  name = "fargate-build"

  retention_in_days = "7" 
}

#Reactビルド時ログ
resource "aws_cloudwatch_log_group" "react-build" {
  name = "react-build"

  retention_in_days = "7" 
}


