resource "aws_security_group" "public_alb" {
  name_prefix = "${var.name}-public-alb-"
  description = "Allows browser traffic to the public load balancer"
  vpc_id      = var.vpc_id

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
  tags = merge(var.tags, { Name = "${var.name}-public-alb-sg" })
}

resource "aws_security_group" "web" {
  name_prefix = "${var.name}-web-"
  description = "Allows HTTP only from the public load balancer"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-web-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "web_from_public_alb" {
  security_group_id            = aws_security_group.web.id
  referenced_security_group_id = aws_security_group.public_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "internal_alb" {
  name_prefix = "${var.name}-internal-alb-"
  description = "Allows HTTP only from web compute"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-internal-alb-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "internal_alb_from_web" {
  security_group_id            = aws_security_group.internal_alb.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-app-"
  description = "Allows HTTP only from the internal load balancer"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, { Name = "${var.name}-app-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "app_from_internal_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.internal_alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name}-database-"
  description = "Allows PostgreSQL only from the application compute"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-database-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "database_from_app" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
