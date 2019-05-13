resource "aws_lb" "main" {
  name               = "${var.product}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [
    "${var.lb_security_groups}"
  ]
  subnets            = [
    "${var.public_subnets}"
  ]

  tags = {
    Name = "${var.product}"
    Environment = "${var.environment}"
  }
}

resource "aws_lb_target_group" "http" {
  name     = "${var.product}-http"
  port     = 81
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    path = "/"
    interval = 30
    port = 80
  }
}

resource "aws_lb_target_group" "https" {
  name     = "theone-https"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${local.vpc_id}"
  deregistration_delay = 60

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    path = "/"
    interval = 30
    protocol = "HTTP"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.http.arn}"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = "${aws_lb.main.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.https.arn}"
  }
}

data "template_file" "launch_config" {
  template = "${file("${path.module}/user_data.sh")}"
  vars {
    playbook = "${var.product}.yml"
  }
}

data "aws_ami" "main" {
  most_recent = true
  owners = ["self"]

  filter = {
    name = "tag:packer"
    values = ["true"]
  }

  filter = {
    name = "tag:role"
    values = ["${var.product}"]
  }
}

resource "aws_launch_configuration" "main" {
  name   = "${var.product}-${var.ci_commit_sha}"
  image_id      = "${data.aws_ami.main.id}"
  instance_type = "${var.instance_type}"
  key_name      = "kyle"
  associate_public_ip_address = false
  iam_instance_profile = "${var.iam_instance_profile}"
  user_data = "${data.template_file.launch_config.rendered}"
  security_groups = [
    "${var.ec2_security_groups}"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "main" {
  name                 = "${aws_launch_configuration.main.name}-asg"
  launch_configuration = "${aws_launch_configuration.main.name}"
  desired_capacity     = 1
  min_size             = 1
  max_size             = 1
  health_check_type    = "ELB"
  vpc_zone_identifier  = [
    "${var.private_subnets}"
  ]
  target_group_arns    = [
    "${aws_lb_target_group.http.arn}",
    "${aws_lb_target_group.https.arn}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key   = "Role"
    value = "${var.iam_instance_profile}"
    propagate_at_launch = true
  }
  tag {
    key   = "Environment"
    value = "${var.environment}"
    propagate_at_launch = true
  }
}
