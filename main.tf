terraform {
  required_version = ">= 0.12"
}

resource "aws_lb" "main" {
  name               = "${var.product}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    var.lb_security_groups,
  ]
  subnets = var.public_subnets

  tags = {
    Name        = var.product
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "http" {
  name                 = "${var.product}-http-${var.environment}"
  port                 = 81
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = var.http_health_check_path
    interval            = 10
    port                = 80
    matcher             = var.http_health_check_matcher
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

resource "aws_lb_target_group" "https" {
  name                 = "${var.product}-https-${var.environment}"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 60

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    path                = var.https_health_check_path
    interval            = 10
    protocol            = "HTTP"
    matcher             = var.http_health_check_matcher
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.https.arn
  }
}

data "template_file" "launch_config" {
  template = file("${path.module}/user_data.sh")
  vars = {
    playbook   = "${var.product}.yml"
    git_branch = var.git_branch
    ci_commit_sha = var.ci_commit_sha
  }
}

data "aws_ami" "main" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:packer"
    values = ["true"]
  }

  filter {
    name   = "tag:role"
    values = [var.product]
  }

}

resource "aws_launch_configuration" "main" {
  name                        = "${var.product}-${var.ci_job_id}-${var.environment}"
  image_id                    = data.aws_ami.main.id
  instance_type               = var.instance_type
  key_name                    = "kyle"
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile
  user_data                   = data.template_file.launch_config.rendered
  security_groups             = var.ec2_security_groups

  lifecycle {
    create_before_destroy = true
  }

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 50
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                      = "${aws_launch_configuration.main.name}-asg"
  launch_configuration      = aws_launch_configuration.main.name
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = var.health_check_type
  wait_for_elb_capacity     = "1"
  health_check_grace_period = 1000
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]
  vpc_zone_identifier = var.private_subnets
  target_group_arns = [
    aws_lb_target_group.http.arn,
    aws_lb_target_group.https.arn,
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Role"
    value               = var.iam_instance_profile
    propagate_at_launch = true
  }
  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "asg-${var.product}"
    propagate_at_launch = true
  }
  tag {
    key   = "datadog"
    value = "monitored"
    propagate_at_launch = true
  }
}
