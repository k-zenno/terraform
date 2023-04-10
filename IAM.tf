resource "aws_iam_role" "ecs_task_exec_role" {
  name = "ecsTaskExecutionRole-CC"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_exec_role_assume_role_policy.json
}

data "aws_iam_policy_document" "ecs_task_exec_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  role = aws_iam_role.ecs_task_exec_role.name
  policy_arn = data.aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn
}

data "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

####################
# IAM Role
####################
resource "aws_iam_role" "codebuild_service_role" {
  name               = "role-codebuild-service-role"
  assume_role_policy = file("./config/codebuild_assume_role.json")
}

resource "aws_iam_role" "codedeploy_service_role" {
  name               = "role-codedeploy-service-role"
  assume_role_policy = file("./config/codedeploy_assume_role.json")
}

resource "aws_iam_role" "codepipeline_service_role" {
  name               = "role-codepipeline-service-role"
  assume_role_policy = file("./config/codepipeline_assume_role.json")
}
 
####################
# IAM Role Policy
####################
 
resource "aws_iam_role_policy" "codebuild_service_role" {
  name   = "build-policy"
  role   = aws_iam_role.codebuild_service_role.name
  policy = file("./config/codebuild_build_policy.json")
}
 
resource "aws_iam_role_policy" "codedeploy_service_role" {
  name   = "deploy-policy"
  role   = aws_iam_role.codedeploy_service_role.name
  policy = file("./config/codedeploy_deploy_policy.json")
}

resource "aws_iam_role_policy" "codepipeline_service_role" {
  name   = "pipeline-policy"
  role   = aws_iam_role.codepipeline_service_role.name
  policy = file("./config/codepipeline_pipeline_policy.json")
}

####################
# EC2用
####################
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "MyRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "cloudwatch_agent" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.cloudwatch_agent.arn
}

resource "aws_iam_instance_profile" "systems_manager" {
  name = "MyInstanceProfile"
  role = aws_iam_role.role.name
}