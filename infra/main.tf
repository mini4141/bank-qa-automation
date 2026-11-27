terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.80" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region  = var.region
  profile = "bank-qa-automation-deployer"

  default_tags {
    tags = {
      Project   = "bank-qa-automation"
      Ephemeral = "true"
      ManagedBy = "terraform"
      Owner     = "alvieirvansyah"
    }
  }
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "name" {
  type    = string
  default = "bank-qa"
}

variable "bedrock_model_id" {
  description = "Bedrock chat model or inference profile id used by inquiry-chat"
  type        = string
  default     = "apac.anthropic.claude-3-5-sonnet-20241022-v2:0"
}

variable "bedrock_embed_model_id" {
  type    = string
  default = "amazon.titan-embed-text-v2:0"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
  services = {
    accounts  = { port = 3001, path = "/api/accounts", health = "/api/accounts/healthz", cpu = 256, memory = 512 }
    transfers = { port = 3002, path = "/api/transfers", health = "/api/transfers/healthz", cpu = 256, memory = 512 }
    chat      = { port = 3003, path = "/api/chat", health = "/api/chat/healthz", cpu = 256, memory = 512 }
    web       = { port = 80, path = "", health = "/healthz", cpu = 256, memory = 512 }
  }
}

# ---------------------------------------------------------------- network (no NAT gateway)
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.name}-public-${count.index}" }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 10)
  availability_zone = local.azs[count.index]
  tags              = { Name = "${var.name}-private-${count.index}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "tasks" {
  name_prefix = "${var.name}-tasks-"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 80
    to_port         = 3003
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name}-db-"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.tasks.id]
  }
}

# ---------------------------------------------------------------- database and secrets
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_db_subnet_group" "main" {
  name       = var.name
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_db_instance" "main" {
  identifier              = var.name
  engine                  = "postgres"
  engine_version          = "16"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_name                 = "bank"
  username                = "bank"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0
  apply_immediately       = true
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/database-url"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = "postgres://bank:${random_password.db.result}@${aws_db_instance.main.address}:5432/bank"
}

resource "aws_secretsmanager_secret" "llm" {
  name                    = "${var.name}/llm-config"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "llm" {
  secret_id = aws_secretsmanager_secret.llm.id
  secret_string = jsonencode({
    BEDROCK_MODEL_ID       = var.bedrock_model_id
    BEDROCK_EMBED_MODEL_ID = var.bedrock_embed_model_id
  })
}

# ---------------------------------------------------------------- registries and logs
resource "aws_ecr_repository" "svc" {
  for_each             = local.services
  name                 = "${var.name}/${each.key}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
}

resource "aws_cloudwatch_log_group" "svc" {
  for_each          = local.services
  name              = "/ecs/${var.name}/${each.key}"
  retention_in_days = 1
}

# ---------------------------------------------------------------- IAM
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name               = "${var.name}-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  role = aws_iam_role.execution.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = [aws_secretsmanager_secret.db.arn, aws_secretsmanager_secret.llm.arn]
    }]
  })
}

resource "aws_iam_role" "chat_task" {
  name               = "${var.name}-chat-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy" "chat_bedrock" {
  role = aws_iam_role.chat_task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
      Resource = "*"
    }]
  })
}

# ---------------------------------------------------------------- load balancer
resource "aws_lb" "main" {
  name               = var.name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "svc" {
  for_each             = local.services
  name                 = "${var.name}-${each.key}"
  port                 = each.value.port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 5
  health_check {
    path                = each.value.health
    interval            = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc["web"].arn
  }
}

resource "aws_lb_listener_rule" "api" {
  for_each     = { for k, v in local.services : k => v if k != "web" }
  listener_arn = aws_lb_listener.http.arn
  priority     = 10 + index(keys(local.services), each.key)
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.svc[each.key].arn
  }
  condition {
    path_pattern {
      values = ["${each.value.path}/*"]
    }
  }
}

# ---------------------------------------------------------------- ECS
resource "aws_ecs_cluster" "main" {
  name = var.name
}

locals {
  alb_url = "http://${aws_lb.main.dns_name}"

  environment = {
    accounts = [
      { name = "PORT", value = "3001" },
      { name = "ROUTE_PREFIX", value = "/api/accounts" },
    ]
    transfers = [
      { name = "PORT", value = "3002" },
      { name = "ROUTE_PREFIX", value = "/api/transfers" },
      { name = "ACCOUNTS_URL", value = "${local.alb_url}/api/accounts" },
    ]
    chat = [
      { name = "ROUTE_PREFIX", value = "/api/chat" },
      { name = "LLM_PROVIDER", value = "bedrock" },
      { name = "AWS_REGION", value = var.region },
    ]
    web = [
      { name = "ACCOUNTS_UPSTREAM", value = aws_lb.main.dns_name },
      { name = "TRANSFERS_UPSTREAM", value = aws_lb.main.dns_name },
      { name = "CHAT_UPSTREAM", value = aws_lb.main.dns_name },
    ]
  }

  secrets = {
    accounts  = [{ name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.db.arn }]
    transfers = [{ name = "DATABASE_URL", valueFrom = aws_secretsmanager_secret.db.arn }]
    chat = [
      { name = "BEDROCK_MODEL_ID", valueFrom = "${aws_secretsmanager_secret.llm.arn}:BEDROCK_MODEL_ID::" },
      { name = "BEDROCK_EMBED_MODEL_ID", valueFrom = "${aws_secretsmanager_secret.llm.arn}:BEDROCK_EMBED_MODEL_ID::" },
    ]
    web = []
  }
}

resource "aws_ecs_task_definition" "svc" {
  for_each                 = local.services
  family                   = "${var.name}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = each.value.cpu
  memory                   = each.value.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = each.key == "chat" ? aws_iam_role.chat_task.arn : null

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name         = each.key
    image        = "${aws_ecr_repository.svc[each.key].repository_url}:latest"
    essential    = true
    portMappings = [{ containerPort = each.value.port }]
    environment  = local.environment[each.key]
    secrets      = local.secrets[each.key]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.svc[each.key].name
        awslogs-region        = var.region
        awslogs-stream-prefix = each.key
      }
    }
  }])
}

resource "aws_ecs_service" "svc" {
  for_each                           = local.services
  name                               = each.key
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.svc[each.key].arn
  desired_count                      = 1
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 120
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.svc[each.key].arn
    container_name   = each.key
    container_port   = each.value.port
  }

  depends_on = [aws_lb_listener.http, aws_secretsmanager_secret_version.db, aws_secretsmanager_secret_version.llm]
}

# ---------------------------------------------------------------- outputs
output "alb_url" {
  value = local.alb_url
}

output "ecr_repositories" {
  value = { for k, r in aws_ecr_repository.svc : k => r.repository_url }
}

output "ecs_cluster" {
  value = aws_ecs_cluster.main.name
}

output "rds_identifier" {
  value = aws_db_instance.main.identifier
}
