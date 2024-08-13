terraform {

  backend "s3" {
    bucket = "govuk-fe-demo-terraform-state-backend"
    key = "terraform.tfstate"
    region = "eu-west-2"
    dynamodb_table = "terraform_state"
  }

}


provider "aws" {
  region = var.aws_region
}


#VPC
resource "aws_vpc" "tf_vpc_main" {
  cidr_block       = var.aws_vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "tf_vpc_main"
  }
}


#Subnets
resource "aws_subnet" "tf_subnet_main" {
  vpc_id     = aws_vpc.tf_vpc_main.id
  cidr_block = var.aws_subnet_main_cidr_block
  availability_zone = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_main"
  }
}

resource "aws_subnet" "tf_subnet_secondary" {
  vpc_id     = aws_vpc.tf_vpc_main.id
  cidr_block = var.aws_subnet_secondary_cidr_block
  availability_zone = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "tf_subnet_secondary"
  }
}


# data "aws_subnets" "tf_subnets_main" {
#   filter {
#     name   = "vpc-id"
#     values = [aws_vpc.tf_vpc_main.id]
#   }
# }

# data "aws_subnet" "tf_subnets_subnet" {
#   for_each = { for index, subnetid in data.aws_subnets.tf_subnets_main.ids : index => subnetid }
# #toset(data.aws_subnets.tf_subnets_main.ids)
#   id       = each.value
# }

# output "tf_subnet_id" {
#   value = [for s in data.aws_subnet.tf_subnets_subnet : s.id]
# }

#Internet Gateway
resource "aws_internet_gateway" "tf_gw" {
  vpc_id = aws_vpc.tf_vpc_main.id

  tags = {
    Name = "tf_gw"
  }
}

# Routing Table
resource "aws_route_table" "tf_route_tb" {
  vpc_id = aws_vpc.tf_vpc_main.id

  route {
    cidr_block = var.aws_route_table_cidr_block
    gateway_id = aws_internet_gateway.tf_gw.id
  }

  # route {
  #   ipv6_cidr_block        = "::/0"
  #   egress_only_gateway_id = aws_egress_only_internet_gateway.example.id
  # }

  tags = {
    Name = "tf_route_tb"
  }
}

# Routing Table Assoc
resource "aws_route_table_association" "tf_rta" {
  subnet_id      = aws_subnet.tf_subnet_main.id
  route_table_id = aws_route_table.tf_route_tb.id
}


resource "aws_route_table_association" "tf_rtb" {
  subnet_id      = aws_subnet.tf_subnet_secondary.id
  route_table_id = aws_route_table.tf_route_tb.id
}



# Security Group
resource "aws_security_group" "tf_sg_main" {
  name        = "tf_sg_main"
  description = "Allow HTTP/HTTPS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.tf_vpc_main.id
  lifecycle {
    create_before_destroy = true
    # Reference the security group as a whole or individual attributes like `name`
    #replace_triggered_by = [aws_security_group.tf_sg_main]
  }
  tags = {
    Name = "tf_sg_main"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = var.aws_security_group_ingress_cidr_block #aws_vpc.tf_vpc_main.cidr_block
  from_port         = var.port
  ip_protocol       = "tcp"
  to_port           = var.port
}

# resource "aws_vpc_security_group_ingress_rule" "https" {
#   security_group_id = aws_security_group.tf_sg_main.id
#   cidr_ipv4         = aws_vpc.tf_vpc_main.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.tf_sg_main.id
  cidr_ipv4         = var.aws_security_group_egress_cidr_block
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#VPC -  Security Group
# module "vpc" {
#   source = "./modules/vpc"
#   aws_cidr_blocks = var.aws_cidr_blocks
#   #aws_subnet_cidr_blocks = var.aws_subnet_cidr_blocks
#   aws_availability_zones = var.aws_availability_zones
# }

#ALB
resource "aws_lb" "tf_lb_test" {
  name               = var.aws_elb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_sg_main.id]
  subnets = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
  #subnets            = [for subnet in aws_subnet.tf_subnet_main : subnet.id]


  enable_deletion_protection = false

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.id
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

#Target Group
resource "aws_lb_target_group" "tf_tg_main" {
  name     = var.aws_elb_target_group_name
  port     = var.port
  protocol = "HTTP"
  target_type = "ip"
  vpc_id   = aws_vpc.tf_vpc_main.id
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.tf_lb_test.arn
  port              = var.port
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
  }
}

# resource "aws_lb_listener" "front_end_secured" { # Requires an SSL Certificate - Lets Encrypt?
#   load_balancer_arn = aws_lb.tf_lb_test.arn
#   port              = "80"
#   protocol          = "HTTPS"
#   #ssl_policy        = "ELBSecurityPolicy-2016-08"
#   #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.tf_tg_main.arn
#   }
# }

# ALB - Listener
# module "elb" {
#   source = "./modules/elb"
# }

#ECR
resource "aws_ecr_repository" "tf_govuk_fe_wtf_demo_ecr_repo" {
  name = var.aws_ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "aws_ecr_lifecycle_policy" "tf_private_ecr_life_pol" {
  repository = aws_ecr_repository.tf_govuk_fe_wtf_demo_ecr_repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# # data "aws_iam_user" "user" {
# #   user_name = "adeolu"
# # }


#ECS Cluster
resource "aws_ecs_cluster" "tf_ecs_cluster" {
  name = var.aws_ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging    = "NONE"

      
      # logging    = "OVERRIDE"

      # log_configuration {
      #   cloud_watch_encryption_enabled = true
      #   cloud_watch_log_group_name     = aws_cloudwatch_log_group.tf_cloud_watch.name
      # }
    }
  }
}

#Task Definition
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_ecr_repository" "repo_details" {
  name = aws_ecr_repository.tf_govuk_fe_wtf_demo_ecr_repo.name
}


resource "aws_ecs_task_definition" "tf_task_def" {
  family                   = var.aws_task_def
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = var.aws_ecs_task_df_container_name
      image     = "${data.aws_ecr_repository.repo_details.repository_url}/${var.aws_ecr_repo_name}:latest"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = var.port
          hostPort      = var.port
          protocol      = "tcp"
        }
      ]
    }
  ])

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

}


#ECS Service
resource "aws_ecs_service" "tf_govuk_service" {
  name            = var.aws_ecs_name
  cluster         = aws_ecs_cluster.tf_ecs_cluster.id
  task_definition = aws_ecs_task_definition.tf_task_def.arn
  launch_type = "FARGATE"
  platform_version = "LATEST"
  desired_count   = 2
  network_configuration {
    security_groups    = [aws_security_group.tf_sg_main.id]
    subnets = [aws_subnet.tf_subnet_main.id, aws_subnet.tf_subnet_secondary.id]
    assign_public_ip = true
}

  load_balancer {
    target_group_arn = aws_lb_target_group.tf_tg_main.arn
    container_name   = var.aws_ecs_task_df_container_name
    container_port   = var.port
  }
}

# module "ecr-ecs" {
#   source = "./modules/ecr-ecs"
# }