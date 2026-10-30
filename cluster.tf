#eks

#terraform cluster

provider "aws" {

    region = "ap-south-1"
}

#iam role
resource "aws_iam_role" "cluster" {
    name = "eks-cluster"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "sts:AssumeRole",
                    "sts:TagSession"
                ]
                Effect ="Allow"
                Principal = {
                    Service = "eks.amazonaws.com"
                }
            },
        ]
    })
}


#role attachment

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.cluster.name   
}

#default vpc
data "aws_vpc" "default" {
    default = true 
}

#default subets
data "aws_subnets" "default" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}

#cluster
resource "aws_eks_cluster" "cluster" {
    name = "cluster"
    role_arn = aws_iam_role.cluster.arn
    access_config {
        authentication_mode ="API"

    }
    version = "1.34"
    vpc_config {
        subnet_ids = data.aws_subnets.default.ids
    }
    depends_on = [aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy]
}

 resource "aws_eks_node_group" "nodegp" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "nodegp"
  node_role_arn   = aws_iam_role.cluster.arn
  subnet_ids      = aws_subnet.default.id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }


  depends_on = [
    aws_iam_role_policy_attachment.nodegp-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodegp-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodegp-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodegp-AmazonSSMManagedInstanceCore4
  ]
}
