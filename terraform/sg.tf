resource "aws_security_group" "jenkins-sg" {
  name = "jenkins-sg"
  description = "jenkins-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    security_groups = [aws_security_group.jenkins_alb_sg.id]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["109.186.208.253/32"]
  }


  tags = {
    Environment = "mid project"
  }
}

resource "aws_security_group" "jenkins_alb_sg" {
  name = "jenkins_alb_sg"
  description = "Allow Jenkins inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "109.186.208.253/32"
    ]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    description = "Allow all outgoing traffic"
    from_port = 0
    to_port = 0
    // -1 means all
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Environment = "mid project"
  }
}