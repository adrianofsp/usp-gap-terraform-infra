ssh_key_path     = "./secrets"
generate_ssh_key = true

# user_data = [
#   "yum install -y postgresql-client-common"
# ]
# security_groups = []
instance_type = "t3a.nano"

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