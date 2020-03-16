resource "aws_iam_role" "test-role-node" {
  name = "test-role-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.test-role-node.id

  policy = <<-EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:DescribeTags"
        ],
      "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "test-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.test-role-node.name
}

resource "aws_iam_role_policy_attachment" "test-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.test-role-node.name
}

resource "aws_iam_role_policy_attachment" "test-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.test-role-node.name
}

resource "aws_security_group" "test-node-sg" {
  name        = "test-node-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.test-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "test-node-sg"
  }
}


resource "aws_security_group_rule" "test-node-rule" {
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.test-sg.id
  security_group_id        = aws_security_group.test-node-sg.id
}

resource "aws_security_group_rule" "test-node-rule2" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.test-sg.id
  security_group_id        = aws_security_group.test-node-sg.id
}

resource "aws_eks_node_group" "worker-group" {
  cluster_name    = aws_eks_cluster.test.name
  node_group_name = "worker_group"
  node_role_arn   = aws_iam_role.test-role-node.arn
  subnet_ids      = aws_subnet.test-subnet[*].id
  instance_types   = ["t3.small"]

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  tags = {
    "k8s.io/cluster-autoscaler/test" = "",
    "k8s.io/cluster-autoscaler/enabled" = ""
  }

  depends_on = [
    aws_iam_role_policy_attachment.test-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.test-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.test-node-AmazonEC2ContainerRegistryReadOnly,
  ]
}