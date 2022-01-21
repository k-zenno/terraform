# Task Definition
# https://www.terraform.io/docs/providers/aws/r/ecs_task_definition.html
resource "aws_ecs_task_definition" "CC" {
  family = "CC_taskdefinition"
  execution_role_arn       = aws_iam_role.ecs_task_exec_role.arn
  # データプレーンの選択
  requires_compatibilities = ["FARGATE"]

  # ECSタスクが使用可能なリソースの上限
  # タスク内のコンテナはこの上限内に使用するリソースを収める必要があり、メモリが上限に達した場合OOM Killer にタスクがキルされる
  cpu    = "256"
  memory = "512"

  # ECSタスクのネットワークドライバ
  # Fargateを使用する場合は"awsvpc"決め打ち
  network_mode = "awsvpc"

  # 起動するコンテナの定義
  # 「nginxを起動し、80ポートを開放する」設定を記述。
  container_definitions = <<EOL
  [
    {
    "name": "CC_container",
    "image": "zenno-test-ecr:1.0",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
    }
  ]
  EOL
}

#クラスター
resource "aws_ecs_cluster" "cluster" {
  name = "Cluster_Childcare"
}


# ECS Service
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
    assign_public_ip = "false"
  }
  
  
  # ECSタスクの起動後に紐付けるELBターゲットグループ
  load_balancer {
      target_group_arn = aws_lb_target_group.TG_Childcare_Blue.arn
      container_name   = "CC_container"
      container_port   = "80"
    }
  
  scheduling_strategy = "REPLICA"
  
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}