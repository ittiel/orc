# -----------------------------------------------------------------------------
# Service role allowing AWS to manage resources required for ECS
# -----------------------------------------------------------------------------

resource "aws_iam_service_linked_role" "ecs_service" {
  aws_service_name = "ecs.amazonaws.com"
  count            = var.create_iam_service_linked_role ? 1 : 0
}


# -----------------------------------------------------------------------------
# Create VPC
# -----------------------------------------------------------------------------

# Fetch AZs in the current region
data "aws_availability_zones" "available" {
}

resource "aws_vpc" "orca" {
  cidr_block           = "172.17.0.0/16"
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  tags = {
    Name = "orca"
  }
}

# Create var.az_count private subnets for RDS, each in a different AZ
resource "aws_subnet" "orca_private" {
  count             = var.az_count
  cidr_block        = cidrsubnet(aws_vpc.orca.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.orca.id

  tags = {
    Name = "orca #${count.index} (private)"
  }
}

# Create var.az_count public subnets for orca, each in a different AZ
resource "aws_subnet" "orca_public" {
  count                   = var.az_count
  cidr_block              = cidrsubnet(aws_vpc.orca.cidr_block, 8, var.az_count + count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  vpc_id                  = aws_vpc.orca.id
  map_public_ip_on_launch = true

  tags = {
    Name = "orca #${var.az_count + count.index} (public)"
  }
}

# IGW for the public subnet
resource "aws_internet_gateway" "orca" {
  vpc_id = aws_vpc.orca.id

  tags = {
    Name = "orca"
  }
}

# Route the public subnet traffic through the IGW
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.orca.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.orca.id
}



# -----------------------------------------------------------------------------
# Create security groups
# -----------------------------------------------------------------------------

# Internet to ALB
resource "aws_security_group" "orca_alb" {
  name        = "orca-alb"
  description = "Allow access on port 443 only to ALB"
  vpc_id      = aws_vpc.orca.id

  ingress {
    protocol    = "tcp"
    from_port   = 5000
    to_port     = 5000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB TO ECS
resource "aws_security_group" "orca_ecs" {
  name        = "orca-tasks"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.orca.id

  ingress {
    protocol        = "tcp"
    from_port       = "5000"
    to_port         = "5000"
    security_groups = [aws_security_group.orca_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS to RDS
resource "aws_security_group" "orca_rds" {
  name        = "orca-rds"
  description = "allow inbound access from the orca tasks only"
  vpc_id      = aws_vpc.orca.id

  ingress {
    protocol        = "tcp"
    from_port       = "5432"
    to_port         = "5432"
    security_groups = concat([aws_security_group.orca_ecs.id], var.additional_db_security_groups)
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -----------------------------------------------------------------------------
# Create RDS
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "orca" {
  name       = "orca"
  subnet_ids = aws_subnet.orca_private.*.id
}

resource "aws_db_instance" "orca" {
  name                   = var.rds_db_name
  identifier             = "orca"
  username               = var.rds_username
  password               = var.rds_password
  port                   = "5432"
  engine                 = "postgres"
  engine_version         = "10.5"
  instance_class         = var.rds_instance
  allocated_storage      = "10"
  storage_encrypted      = var.rds_storage_encrypted
  vpc_security_group_ids = [aws_security_group.orca_rds.id]
  db_subnet_group_name   = aws_db_subnet_group.orca.name
  parameter_group_name   = "default.postgres10"
  multi_az               = var.multi_az
  storage_type           = "gp2"
  publicly_accessible    = false

  # snapshot_identifier       = "orca"
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = false
  apply_immediately           = true
  maintenance_window          = "sun:02:00-sun:04:00"
  skip_final_snapshot         = false
  copy_tags_to_snapshot       = true
  backup_retention_period     = 7
  backup_window               = "04:00-06:00"
  final_snapshot_identifier   = "orca"

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Create ECS cluster
# -----------------------------------------------------------------------------

resource "aws_ecs_cluster" "orca" {
  name = var.ecs_cluster_name
}



# -----------------------------------------------------------------------------
# Create a task definition
# -----------------------------------------------------------------------------

locals {
  ecs_environment = [
    {
      name  = "orca_DATABASE_URL",
      value = "postgres://${var.rds_username}:${var.rds_password}@${aws_db_instance.orca.endpoint}"
    }
  ]

  ecs_container_definitions = [
    {
      image       = "strm/helloworld-http:${var.orca_version_tag}"
      name        = "orca",
      networkMode = "awsvpc",

      portMappings = [
        {
          containerPort = 5000,
          hostPort      = 5000
        }
      ]
      environment = flatten([local.ecs_environment, var.environment])
    }
  ]
}

resource "aws_ecs_task_definition" "orca" {
  family                   = "orca"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
#  execution_role_arn       = aws_iam_role.orca_role.arn

  container_definitions = jsonencode(local.ecs_container_definitions)
}

# -----------------------------------------------------------------------------
# Create the ECS service
# -----------------------------------------------------------------------------

resource "aws_ecs_service" "orca" {
  depends_on = [
    aws_ecs_task_definition.orca,
    aws_alb_listener.orca
  ]
  name            = "orca-service"
  cluster         = aws_ecs_cluster.orca.id
  task_definition = aws_ecs_task_definition.orca.arn
  desired_count   = var.multi_az == true ? "2" : "1"
  launch_type     = "FARGATE"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.orca_ecs.id]
    subnets          = aws_subnet.orca_public.*.id
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.orca.id
    container_name   = "orca"
    container_port   = "5000"
  }
}


# -----------------------------------------------------------------------------
# Create the ALB
# -----------------------------------------------------------------------------

resource "aws_alb" "orca" {
  name            = "orca-alb"
  subnets         = aws_subnet.orca_public.*.id
  security_groups = [aws_security_group.orca_alb.id]

}

# -----------------------------------------------------------------------------
# Create the ALB target group for ECS
# -----------------------------------------------------------------------------

resource "aws_alb_target_group" "orca" {
  name        = "orca-alb"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.orca.id
  target_type = "ip"

  health_check {
    path    = "/_healthz"
    matcher = "200"
  }
}

# -----------------------------------------------------------------------------
# Create the ALB listener
# -----------------------------------------------------------------------------

resource "aws_alb_listener" "orca" {
  load_balancer_arn = aws_alb.orca.id
  port              = "5000"
  protocol          = "HTTP"
#  certificate_arn   = aws_acm_certificate.orca.arn

  default_action {
    target_group_arn = aws_alb_target_group.orca.id
    type             = "forward"
  }
}


