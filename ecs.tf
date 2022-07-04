resource "aws_ecs_cluster" "default" {
  name = module.this.id
  tags = module.this.tags
}

module "sg" {
  source     = "cloudposse/security-group/aws"
  version    = "1.0.1"
  attributes = ["primary"]
  namespace  = var.namespace
  stage      = var.stage
  name       = "observability"

  # Allow unlimited egress
  allow_all_egress = true

  rules = [
    {
      key         = "HTTP"
      type        = "ingress"
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      self        = null
      description = "Allow HTTP access to grafana"
    }
  ]

  vpc_id = module.vpc.vpc_id

  context = module.this.context
}

module "alb" {
  source                                  = "cloudposse/alb/aws"
  version                                 = "0.27.0"
  namespace                               = var.namespace
  stage                                   = var.stage
  name                                    = "alb"
  vpc_id                                  = module.vpc.vpc_id
  security_group_ids                      = [module.sg.id]
  subnet_ids                              = module.dynamic-subnets.public_subnet_ids
  internal                                = false
  http_enabled                            = true
  access_logs_enabled                     = true
  alb_access_logs_s3_bucket_force_destroy = true
  cross_zone_load_balancing_enabled       = true
  http2_enabled                           = true
  deletion_protection_enabled             = false
  http_port                               = 80
  target_group_port                       = 3000

  context = module.this.context
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.1"

  container_name               = var.container_name
  container_image              = var.container_image
  container_memory             = var.container_memory
  container_memory_reservation = var.container_memory_reservation
  container_cpu                = var.container_cpu
  essential                    = var.essential
  readonly_root_filesystem     = var.readonly_root_filesystem
  environment                  = var.container_environment
  port_mappings                = var.container_port_mappings

  log_configuration = {
    logDriver = "awslogs"
    options = {
      "awslogs-region"        = var.region
      "awslogs-group"         = "iot-grafana-fargate"
      "awslogs-create-group"  = "true"
      "awslogs-stream-prefix" = "grafana"
    }
    secretOptions = null
  }

  map_environment = {
    "GF_DATABASE_HOST"          = "acmedb.cbgvxyfea0se.us-east-1.rds.amazonaws.com:3306"
    "GF_DATABASE_NAME"          = "grafana"
    "GF_DATABASE_USER"          = "admin"
    "GF_DATABASE_PASSWORD"      = "Davinci$1973"
    "GF_DATABASE_TYPE"          = "mysql"
    "GF_DATABASE_MAX_OPEN_CONN" = "300"
    "GF_LOG_CONSOLE_FORMAT"     = "json"
  }
}

module "ecs_alb_service_task" {
  source                             = "cloudposse/ecs-alb-service-task/aws"
  version                            = "0.64.0"
  namespace                          = var.namespace
  stage                              = var.stage
  name                               = "grafana"
  alb_security_group                 = module.vpc.vpc_default_security_group_id
  container_definition_json          = module.container_definition.json_map_encoded_list
  ecs_cluster_arn                    = aws_ecs_cluster.default.arn
  launch_type                        = var.launch_type
  vpc_id                             = module.vpc.vpc_id
  security_group_ids                 = [module.sg.id]
  subnet_ids                         = module.dynamic-subnets.public_subnet_ids
  ignore_changes_task_definition     = var.ignore_changes_task_definition
  network_mode                       = var.network_mode
  assign_public_ip                   = var.assign_public_ip
  propagate_tags                     = var.propagate_tags
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_controller_type         = var.deployment_controller_type
  desired_count                      = var.desired_count
  task_memory                        = var.task_memory
  task_cpu                           = var.task_cpu
  security_group_enabled             = var.security_group_enabled
  ephemeral_storage_size             = 30
  # log_configuration = "awslogs"
  # docker_volumes = [{
  #   host_path = "/var/lib/grafana"
  #   name      = "grafana"
  #   docker_volume_configuration = [{
  #     autoprovision = true
  #     driver        = "local"
  #     driver_opts   = {}
  #     labels        = {}
  #     scope         = "shared"
  #   }]
  # }]

  ecs_load_balancers = [{
    container_name   = var.container_name
    container_port   = var.container_port
    elb_name         = null
    target_group_arn = module.alb.default_target_group_arn
  }]
}

module "ecs_cloudwatch_autoscaling" {
  source                = "cloudposse/ecs-cloudwatch-autoscaling/aws"
  version               = "0.7.3"
  namespace             = var.namespace
  stage                 = var.stage
  name                  = "grafana-autoscaling"
  context               = module.this.context
  cluster_name          = aws_ecs_cluster.default.name
  service_name          = module.ecs_alb_service_task.service_name
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  scale_up_adjustment   = var.scale_up_adjustment
  scale_up_cooldown     = var.scale_up_cooldown
  scale_down_adjustment = var.scale_down_adjustment
  scale_down_cooldown   = var.scale_down_cooldown
}

#------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU High
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "grafana-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.max_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.max_cpu_period
  statistic           = "Maximum"
  threshold           = var.max_cpu_threshold
  dimensions = {
    ClusterName = aws_ecs_cluster.default.name
    ServiceName = module.ecs_alb_service_task.service_name
  }
  alarm_actions = [module.ecs_cloudwatch_autoscaling.scale_up_policy_arn]

  tags = var.tags
}

------------------------------------------------------------------------------
# AWS Auto Scaling - CloudWatch Alarm CPU Low
#------------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "grafana-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.min_cpu_evaluation_period
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.min_cpu_period
  statistic           = "Average"
  threshold           = var.min_cpu_threshold
  dimensions = {
    ClusterName = aws_ecs_cluster.default.name
    ServiceName = module.ecs_alb_service_task.service_name
  }
  alarm_actions = [module.ecs_cloudwatch_autoscaling.scale_down_policy_arn]

  tags = var.tags
}