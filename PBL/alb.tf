#--- loadbalancing/main.tf

#create external application load balancer
resource "aws_lb" "ext-alb" {
  name            = "pbl-ext-alb"
  internal        = false
  security_groups = [aws_security_group.ext-alb-sg.id]

  subnets = [
    aws_subnet.pbl-public[0].id,
    aws_subnet.pbl-public[1].id
  ]

  tags = merge(
    var.tags,
    {
      Name = "pbl-ext-alb"
    },
  )

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

#create target groups to inform external alb where to route traffic to
resource "aws_lb_target_group" "nginx-tg" {
  health_check {
    interval            = 10
    path                = "/healthstatus"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
  name        = "nginx-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

#create listener group for this target group
resource "aws_lb_listener" "nginx-listner" {
  load_balancer_arn = aws_lb.ext-alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.mayorfaj.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx-tg.arn
  }
}


#create internal application load balancer
resource "aws_lb" "int_alb" {
  name               = "pbl-int-alb"
  internal           = true
  ip_address_type    = "ipv4"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.int-alb-sg.id]

  subnets = [
    aws_subnet.pbl-private[0].id,
    aws_subnet.pbl-private[1].id
  ]
  tags = merge(
    var.tags,
    {
      Name = "pbl-int-alb"
    }
  )
}

#create target group to inform internal alb wher to direct traffic
#target group for wordpress---
resource "aws_lb_target_group" "wordpress-tg" {
  name        = "wordpress-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    interval            = 10
    path                = "/healthstatus"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

#target group for tooling ----
resource "aws_lb_target_group" "tooling-tg" {
  name        = "tooling-tg"
  port        = 443
  protocol    = "HTTPS"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    interval            = 10
    path                = "/healthstatus"
    protocol            = "HTTPS"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}


#create a listener for the target
#For this aspect a single listener was created for the wordpress which is default,
# A rule was created to route traffic to tooling when the host header changes

resource "aws_lb_listener" "webserver-listener" {
  load_balancer_arn = aws_lb.int_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.mayorfaj.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress-tg.arn
  }
}

#listener rule for tooling target
resource "aws_lb_listener_rule" "tooling-listener" {
  listener_arn = aws_lb_listener.webserver-listener.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tooling-tg.arn
  }

  condition {
    host_header {
      values = ["tooling.mayorfaj.io"]
    }
  }
}