//resource "aws_lb" "jenkins-alb" {
  //name               = "jenkins-alb"
  //internal           = false
  //load_balancer_type = "application"
  //security_groups    = [aws_security_group.jenkins_alb_sg.id]
  //subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

  //enable_deletion_protection = true

  //tags = {
  //  Environment = "mid project"
  //}
//}