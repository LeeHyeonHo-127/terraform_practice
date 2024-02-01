# Provider 

provider "aws" {
    region = "ap-northeast-2"
}

# Application LoadBalancer Resource

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

# Listener Of ALB

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"
  
 
  # By default, return a simple 404 page  
  default_action {
  type = "fixed-response"
  fixed_response {
  content_type = "text/plain"
  message_body = "404: page not found"
  status_code = 404
  }
  }
}

# LB Listener Rule

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  condition {
   path_pattern {
     values = ["*"]
    }
  }
  action {
     type = "forward"
     target_group_arn = aws_lb_target_group.asg.arn
   }
  }

# Target Group of ALB

resource "aws_lb_target_group" "asg" {
 name = "terraform-asg-example"
 port = var.server_port
 protocol = "HTTP"
 vpc_id = data.aws_vpc.default.id
 health_check {
   path = "/"
   protocol = "HTTP"
   matcher = "200"
   interval = 15
   timeout = 3
   healthy_threshold = 2
   unhealthy_threshold = 2
   }
}


# Security Group for ALB

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"
  
  # Allow inbound HTTP requests
  ingress {
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow all ourbound requests
  egress {
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}



# Launch Configutation Resource

resource "aws_launch_configuration" "example" {
  image_id           = "ami-0f3a440bbcff3d043"
  instance_type = "t3.micro"
  security_groups = [aws_security_group.instance.id]
  
  # Render the User Data Script as a template  
  user_data  =  templatefile("user-data.sh", {
  server_port = var.server_port
  db_address = data.terraform_remote_state.db.outputs.address
  db_port = data.terraform_remote_state.db.outputs.port
  })

  # Required when using a launch configuration with an auto scaling group.
  lifecycle {
      create_before_destroy = true
  }
}



# Autoscaling Group Resource

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size = 2
  max_size = 10
  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
   }
} 


# Security Group Resource for Instance

resource "aws_security_group" "instance" {
   name = "terraform-example-instance"

   ingress {
     from_port     = var.server_port
     to_port       = var.server_port
     protocol      = "tcp"
     cidr_blocks   = [ "0.0.0.0/0" ]
   }
}



