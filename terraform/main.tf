provider "aws" {
  region = var.region
}

resource "aws_security_group" "web_lb_sg" {
  name   = "web-lb-sg"
  vpc_id = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }
}

resource "aws_lb" "web" {
  name               = "web"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.web_lb_sg.id]
  subnets            = [var.subnet_a_id, var.subnet_b_id]
  # These charge-code tags make it easier to tell which resources in my account were
  # provisioned by this challenge
  tags = {
    "charge-code" = "Lendflow"
  }
}

resource "aws_lb_target_group" "web" {
  name        = "web-ecs-tasks"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 30
    matcher             = "200-299"
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    unhealthy_threshold = 3
  }
  tags = {
    "charge-code" = "Lendflow"
  }
}

resource "aws_lb_listener" "web_http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_ecs_cluster" "lendflow_challenge" {
  name               = "lendflow-challenge"
  capacity_providers = ["FARGATE"]
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    "charge-code" = "Lendflow"
  }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "web"
  retention_in_days = var.web_ecs_task_log_retention_days
  tags = {
    "charge-code" = "Lendflow"
  }
}

# I like template files for container definitions because they
# make it easier to organize them
data "template_file" "web_task_definition" {
  template = file("ecs_task_definitions/web.json")
  vars = {
    image_version = var.web_ecs_task_image_version
    log_group     = aws_cloudwatch_log_group.web.name
    region        = var.region
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ECSTaskExecutionRole"
  assume_role_policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_ecs_task_execution_policy_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "web" {
  family                   = "web"
  container_definitions    = data.template_file.web_task_definition.rendered
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  cpu                      = 256
  memory                   = 512
  depends_on = [
    aws_ecs_cluster.lendflow_challenge
  ]
  tags = {
    "charge-code" = "Lendflow"
  }
}

resource "aws_security_group" "web_service_sg" {
  name   = "web-service-sg"
  vpc_id = var.vpc_id
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    security_groups = [aws_security_group.web_lb_sg.id]
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
  }
}

# I chose to ask for scaling value variables because they could change frequently
resource "aws_ecs_service" "web" {
  name                               = "web"
  cluster                            = aws_ecs_cluster.lendflow_challenge.id
  task_definition                    = aws_ecs_task_definition.web.arn
  launch_type                        = "FARGATE"
  desired_count                      = var.web_ecs_task_desired_count
  deployment_maximum_percent         = var.web_ecs_task_max_pct
  deployment_minimum_healthy_percent = var.web_ecs_task_min_pct
  health_check_grace_period_seconds  = 10
  wait_for_steady_state              = true
  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.web_service_sg.id]
    subnets          = [var.subnet_a_id, var.subnet_b_id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 80
  }
  tags = {
    "charge-code" = "Lendflow"
  }
}

resource "aws_cloudwatch_metric_alarm" "web" {
  alarm_name                = "WebServiceNoRunningTasks"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "1"
  threshold                 = "0"
  insufficient_data_actions = []
  metric_query {
    id          = "m1"
    return_data = true
    metric {
      dimensions = {
        ClusterName = aws_ecs_cluster.lendflow_challenge.name
        ServiceName = aws_ecs_service.web.name
      }
      metric_name = "RunningTaskCount"
      namespace   = "ECS/ContainerInsights"
      period      = "1500"
      stat        = "Maximum"
      unit        = "Count"
    }
  }
  alarm_description = "This metric triggers an alarm when no web service tasks are running"
}
