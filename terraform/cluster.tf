resource "aws_iam_role" "test-role" {
  name = "test-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "test-role-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.test-role.name
}

resource "aws_iam_role_policy_attachment" "test-role-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.test-role.name
}

resource "aws_security_group" "test-sg" {
  name        = "test-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.test-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-sg"
  }
}

resource "aws_security_group_rule" "test-sg-ingress-workstation-https" {
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.test-sg.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "test" {
  name     = var.cluster-name
  role_arn = aws_iam_role.test-role.arn

  vpc_config {
    security_group_ids = [aws_security_group.test-sg.id]
    subnet_ids         = aws_subnet.test-subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.test-role-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.test-role-AmazonEKSServicePolicy,
  ]
}