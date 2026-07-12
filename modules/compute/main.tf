data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_lb" "public" {
  name               = "${var.name}-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.public_alb_sg_id]
  subnets            = var.public_subnet_ids
  tags               = var.tags
}

resource "aws_lb_target_group" "web" {
  name     = "${var.name}-web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check { path = "/health" }
  tags = var.tags
}

resource "aws_lb_listener" "public" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.web_instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.web_sg_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <h1>${var.name}: web tier</h1><p>This request reached the web tier.</p>
    HTML
    echo 'ok' > /usr/share/nginx/html/health
    systemctl enable --now nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-web" })
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.name}-web-asg"
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_min_size
  vpc_zone_identifier = var.web_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

resource "aws_lb" "internal" {
  name               = "${var.name}-internal"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.app_subnet_ids
  tags               = var.tags
}

resource "aws_lb_target_group" "app" {
  name     = "${var.name}-app"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check { path = "/health" }
  tags = var.tags
}

resource "aws_lb_listener" "internal" {
  load_balancer_arn = aws_lb.internal.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.app_instance_type
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.app_sg_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    dnf install -y nginx
    cat > /usr/share/nginx/html/index.html <<'HTML'
    <h1>${var.name}: application tier</h1><p>Application tier is healthy.</p>
    HTML
    echo 'ok' > /usr/share/nginx/html/health
    systemctl enable --now nginx
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-app" })
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.name}-app-asg"
  min_size            = var.app_min_size
  max_size            = var.app_max_size
  desired_capacity    = var.app_min_size
  vpc_zone_identifier = var.app_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
}
