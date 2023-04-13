# #Create ALB security group with permissions to web server SG
# resource "aws_security_group" "alb-sg" {
#   name = "terraform-alb-sg"

#   ingress {
#     description = "Allow all HTTP"
#     from_port   = var.HTTP
#     to_port     = var.HTTP
#     protocol    = var.tcp
#     cidr_blocks = [var.cidr]
#   }

#   egress {
#     description = "Allow all outbound"
#     from_port   = var.egress-all
#     to_port     = var.egress-all
#     protocol    = var.egress
#     cidr_blocks = [var.cidr]
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "Terraform ALB SG"
#   }
# }

# #Create internet-facing ALB targeting web servers
# resource "aws_lb" "web-server-alb" {
#   name               = "terraform-web-server-alb"
#   load_balancer_type = "application"
#   subnets            = data.aws_subnets.public.ids
#   security_groups    = [aws_security_group.alb-sg.id]
# }

# #Create ALB listener on port 80 with protocol HTTP
# resource "aws_lb_listener" "web-server-alb" {
#   load_balancer_arn = aws_lb.web-server-alb.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.web-server-alb.arn
#   }
# }

# #Create ALB target group
# resource "aws_lb_target_group" "web-server-alb" {
#   name     = "terraform-alb-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.vpc-tf.id
# }

# #Create ALB listener rules
# resource "aws_lb_listener_rule" "alb-lg" {
#   listener_arn = aws_lb_listener.http.arn
#   priority     = 100

#   condition {
#     path_pattern {
#       values = ["*"]
#     }
#   }
#   action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web-server-instances.arn
#   }
# }