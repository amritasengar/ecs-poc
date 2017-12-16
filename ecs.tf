# our container registry
resource "aws_ecr_repository" "eHa" {
  name = "eHa"
}

# simple security group for our VPC, ingress locked down to Private IPs
resource "aws_security_group" "ecs" {
  name        = "ecs-sg"
  description = "Container Instance Allowed Ports"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 1
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "ecs-sg"
  }
}

# ecs iam role and policies
resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = "${file("policies/ecs-role.json")}"
}

resource "aws_iam_role_policy" "ecs_service_role_policy" {
  name   = "ecs_service_role_policy"
  policy = "${data.template_file.ecs_service_role_policy.rendered}"
  role   = "${aws_iam_role.ecs_role.id}"
}

# ec2 container instance role and policy
resource "aws_iam_role_policy" "ecs_instance_role_policy" {
  name   = "ecs_instance_role_policy"
  policy = "${file("policies/ecs-instance-role-policy.json")}"
  role   = "${aws_iam_role.ecs_role.id}"
}

# IAM profile to be used in auto-scaling launch configuration.
resource "aws_iam_instance_profile" "ecs" {
  name = "ecs-instance-profile"
  path = "/"
  role = "${aws_iam_role.ecs_role.name}"
}

resource "aws_launch_configuration" "ecs" {
  name                 = "ecs"
  image_id             = "${lookup(var.amis, var.aws_region)}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.id}"
  security_groups      = ["${aws_security_group.ecs.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"
  user_data            = "#!/bin/bash\necho ECS_CLUSTER=${aws_ecs_cluster.default.name} > /etc/ecs/ecs.config"
}

# Autoscaling group.
resource "aws_autoscaling_group" "ecs" {
  name                 = "ecs-asg"
  vpc_zone_identifier  = ["${aws_subnet.private_subnet_eu_west_2a.id}", "${aws_subnet.private_subnet_eu_west_2b.id}"]
  launch_configuration = "${aws_launch_configuration.ecs.name}"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
}

# ecs service cluster
resource "aws_ecs_cluster" "default" {
  name = "${var.ecs_cluster_name}"
}
