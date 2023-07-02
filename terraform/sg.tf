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
    cidr_blocks = ["93.173.102.156/32"]
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
    Environment = "final project"
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
    Environment = "final project"
  }
}

resource "aws_security_group" "db_sg" {
  name = "db-sg"
  description = "db-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    self = true
    security_groups = [module.eks.node_security_group_id]
  }

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["93.173.102.156/32"]
  }
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.jenkins-sg.id]
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
    Environment = "final project"
  }
}

resource "aws_security_group" "jenkins-eks-sg" {
  name = "jenkins-eks-sg"
  description = "jenkins-eks-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    security_groups = [aws_security_group.jenkins-sg.id]
  }

  tags = {
    Environment = "final project"
  }
}

resource "aws_security_group" "elk-sg" {
  name = "elk-sg"
  description = "elk-sg"
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
    self = true
    security_groups = [aws_security_group.jenkins-sg.id]
  }

    ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    security_groups = [aws_security_group.db_sg.id]
  }

    ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    self = true
    security_groups = [aws_security_group.jenkins-eks-sg.id]
  }

  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["93.173.102.156/32"]
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
    Environment = "final project"
  }
}