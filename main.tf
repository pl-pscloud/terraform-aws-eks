data "aws_region" "pscloud-region" {}


resource "aws_eks_cluster" "pscloud-eks-cluster" {
  name     = "${var.pscloud_company}_eks_cluster_${var.pscloud_env}_${var.pscloud_project}"
  role_arn = aws_iam_role.pscloud-iam-role-eks.arn

  vpc_config {
    subnet_ids = var.pscloud_subnets_ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.pscloud-iam-eks-cluster-policy,
    aws_iam_role_policy_attachment.pscloud-iam-eks-service-policy,
  ]

  tags = {
    Name            = "${var.pscloud_company}_eks_cluster_${var.pscloud_env}_${var.pscloud_project}"
    Project         = var.pscloud_project
  }
}


//Rendering eks aut-file
data  "template_file" "eks-tpl" {
  template = file("eks.tpl")
  vars = {
    node_role_arn = aws_iam_role.pscloud-iam-role-eks-node-group.arn
  }

}

resource "local_file" "eks-yml" {
  content  = data.template_file.eks-tpl.rendered
  filename = "eks.yaml"

  depends_on = [ data.template_file.eks-tpl, aws_iam_role.pscloud-iam-role-eks-node-group ]
}



resource "null_resource" "pscloud-import-kube-config" {
  # get kub config
  provisioner "local-exec" {
    command = "aws --profile ${var.pscloud_aws_profile}  eks --region ${data.aws_region.pscloud-region.name}  update-kubeconfig --name ${aws_eks_cluster.pscloud-eks-cluster.name}"
  }

  depends_on = [ aws_eks_cluster.pscloud-eks-cluster, local_file.eks-yml ]
}

resource "null_resource" "pscloud-apply-auth" {
  # apply role for node group
  provisioner "local-exec" {
    command = "kubectl apply -f eks.yaml"
  }

  depends_on = [ null_resource.pscloud-import-kube-config, local_file.eks-yml ]
}



resource "aws_eks_node_group" "pscloud-eks-node-group" {
  cluster_name    = aws_eks_cluster.pscloud-eks-cluster.name
  node_group_name = "${var.pscloud_company}_eks_node_group_${var.pscloud_env}_${var.pscloud_project}"
  node_role_arn   = aws_iam_role.pscloud-iam-role-eks-node-group.arn
  subnet_ids      = var.pscloud_subnets_ids_for_node_group

  ami_type        = var.pscloud_ami_type

  instance_types   = var.pscloud_instance_types
  disk_size        = var.pscloud_disk_size

  remote_access{
    ec2_ssh_key       = var.pscloud_ssh_key_name
  }
  //


  scaling_config {
    desired_size = var.pscloud_node_group_desired
    max_size     = var.pscloud_node_group_max
    min_size     = var.pscloud_node_group_min
  }

  tags = {
    Name            = "${var.pscloud_company}_eks_ec2_node_group_${var.pscloud_env}_${var.pscloud_project}"
    Project         = var.pscloud_project
  }

  depends_on = [
    null_resource.pscloud-apply-auth,
    aws_eks_cluster.pscloud-eks-cluster,
    aws_iam_role_policy_attachment.pscloud-iam-eks-worker-node-policy,
    aws_iam_role_policy_attachment.pscloud-iam-eks-cni-policy,
    aws_iam_role_policy_attachment.pscloud-iam-ec2-container-registry-ro,
  ]
}