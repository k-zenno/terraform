####################
#Build
####################
#Fargate用buildproject
resource "aws_codebuild_project" "fargate-build" {
  name         = "fargate-build"
  description  = "fargate-buikd"
  service_role = aws_iam_role.codebuild_service_role.arn
 
  artifacts {
    type = "CODEPIPELINE"
  }
 
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
 
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = "ap-northeast-1"
    }
 
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = "446156192429"
    }
 
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = "fargate-deploy"
    }
 
    environment_variable {
      name  = "IMAGE_TAG"
      value = "1.0"
    }
  }
 
  source {
    type            = "CODEPIPELINE"
    buildspec       = "cicd/buildspec.yml"
  }
 
  vpc_config {
    vpc_id = aws_vpc.vpc_Childcare.id
 
    subnets = [
      aws_subnet.private-a.id,
      aws_subnet.private-c.id
    ]
 
    security_group_ids = [
      aws_security_group.SG_ALB_Childcare.id,
    ]
  }

   logs_config {
    cloudwatch_logs {
      group_name  = "fargate-build"
    }
  }

  depends_on    = [aws_cloudwatch_log_group.fargate-build]
}

#React用buildproject
resource "aws_codebuild_project" "react-build" {
  name         = "react-build"
  description  = "react-build"
  service_role = aws_iam_role.codebuild_service_role.arn
 
  artifacts {
    type = "CODEPIPELINE"
  }
 
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

  }
 
  source {
    type            = "CODEPIPELINE"
    buildspec       = "cicd/buildspec.yml"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "react-build"
    }
  }

  depends_on    = [aws_cloudwatch_log_group.react-build]
}


####################
#Deploy
####################
#アプリケーション
resource "aws_codedeploy_app" "this" {
  compute_platform = "ECS"
  name             = "fargate-deploy"
}

#デプロイメントグループ
resource "aws_codedeploy_deployment_group" "this" {
  app_name               = aws_codedeploy_app.this.name
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  deployment_group_name  = "fargate-deploygroup"
  service_role_arn       = aws_iam_role.codedeploy_service_role.arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 0
    }
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = aws_ecs_service.Childcare_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_alb_listener.alb-blue.arn]
      }
      target_group {
        name = aws_alb_target_group.TG_Childcare_Blue.name
      }
      test_traffic_route {
        listener_arns = [aws_alb_listener.alb-green.arn]
      }
      target_group {
        name = aws_alb_target_group.TG_Childcare_Green.name
      }
    }
  }
}

####################
#Connection
####################
#コンテナ用リポジトリ向け
resource "aws_codestarconnections_connection" "backend-api" {
  name          = "backend-api"
  provider_type = "GitHub"
}

#静的コンテンツ用リポジトリ向け
resource "aws_codestarconnections_connection" "front" {
  name          = "front"
  provider_type = "GitHub"
}

####################
#Pipeline
####################
#Fargate用パイプライン
resource "aws_codepipeline" "fargate-pipeline" {
  name     = "pipeline-fargate-deploy"
  role_arn = aws_iam_role.codepipeline_service_role.arn
 
  artifact_store {
    location = aws_s3_bucket.fargate-pipeline.bucket
    type     = "S3"
  }
 
  stage {
    name = "Source"
 
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
 
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.backend-api.arn
        FullRepositoryId = "bft-developers/bft-dp-backend-api"
        BranchName       = "develop"
      }
    }
  }
 
  stage {
    name = "Build"
 
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
 
      configuration = {
        ProjectName = aws_codebuild_project.fargate-build.name
      }
    }
  }
 
  stage {
    name = "Deploy"
 
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = "1"
 
      configuration = {
        ApplicationName                = aws_codedeploy_app.this.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.this.deployment_group_name
        TaskDefinitionTemplateArtifact = "SourceArtifact"
        TaskDefinitionTemplatePath     = "cicd/taskdef.json"
        AppSpecTemplateArtifact        = "SourceArtifact"
        AppSpecTemplatePath            = "cicd/appspec.yml"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }

      input_artifacts = [
        "BuildArtifact",
        "SourceArtifact"
      ]

      namespace = "DeployVariables"
    }
  }
}

#React用パイプライン
resource "aws_codepipeline" "react-pipeline" {
  name     = "pipeline-react-deploy"
  role_arn = aws_iam_role.codepipeline_service_role.arn
 
  artifact_store {
    location = aws_s3_bucket.react-pipeline.bucket
    type     = "S3"
  }
 
  stage {
    name = "Source"
 
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.front.arn
        FullRepositoryId = "bft-developers/bft-dp-front"
        BranchName       = "develop"
      }
    }
  }
 
  stage {
    name = "Build"
 
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
 
      configuration = {
        ProjectName = aws_codebuild_project.react-build.name
      }
    }
  }
 
  stage {
    name = "Deploy"
 
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
 
      configuration = {
        BucketName    = aws_s3_bucket.static-content.bucket
        Extract = true
      }

      input_artifacts = [
        "BuildArtifact"
      ]

      namespace = "DeployVariables"
    }
  }
}