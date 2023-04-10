####################
# ECR
####################
resource "aws_ecr_repository" "fargate" {
  name = "fargate-deploy"
}


####################
# ECS
####################
# タスク定義
resource "aws_ecs_task_definition" "CC" {
  family = "CC_taskdefinition"
  task_role_arn = aws_iam_role.ecs_task_exec_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn

  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "1024"
  network_mode = "awsvpc"

  container_definitions = file("config/container.json")

  depends_on    = [aws_cloudwatch_log_group.Container_Log]
}


#クラスター
resource "aws_ecs_cluster" "cluster" {
  name = "Cluster_Childcare"
}


#ECS Service
resource "aws_ecs_service" "Childcare_service" {
  name = "Childcare_service"
  cluster = aws_ecs_cluster.cluster.name
  launch_type = "FARGATE"
  desired_count = "1"
  task_definition = aws_ecs_task_definition.CC.arn
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # ECSタスクへ設定するネットワークの設定
  network_configuration {
    subnets         = [aws_subnet.private-a.id, aws_subnet.private-c.id]
    security_groups = [aws_security_group.SG_Fargate_Childcare.id]
    assign_public_ip = "true"
  }
  
  
  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
      target_group_arn = aws_alb_target_group.TG_Childcare_Green.arn
      container_name   = "CC_container"
      container_port   = "80"
    }
  
  scheduling_strategy = "REPLICA"
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }
  
  lifecycle {
    ignore_changes = [
       desired_count,task_definition,load_balancer,
    ]
  }
}