resource "aws_iam_role" "ecs_task_exec_role" {
  name = "ecsTaskExecutionRole"
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