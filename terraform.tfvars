ssh_key_path     = "./secrets"
generate_ssh_key = true
instance_type    = "t3a.nano"

security_group_rules = [
  {
    type        = "egress"
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    type        = "ingress"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# container definition
container_name               = "grafana"
container_image              = "grafana/grafana:latest"
container_memory             = 1024
container_cpu                = 512
container_memory_reservation = 256
container_port               = 3000
container_port_mappings = [
  {
    containerPort = 3000
    hostPort      = 3000
    protocol      = "tcp"
  }
]

# ecs service
launch_type                        = "FARGATE"
ignore_changes_task_definition     = true
network_mode                       = "awsvpc"
assign_public_ip                   = true
propagate_tags                     = "TASK_DEFINITION"
deployment_minimum_healthy_percent = 100
deployment_maximum_percent         = 200
deployment_controller_type         = "ECS"
desired_count                      = 1
task_memory                        = 1024
task_cpu                           = 512

# alb
# alb_ingress_healthcheck_path = "/"

# autoscaling
min_capacity          = 1
max_capacity          = 5
scale_up_adjustment   = 1
scale_up_cooldown     = 60
scale_down_adjustment = -1
scale_down_cooldown   = 300