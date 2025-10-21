# STEP 1: eks(Elastic Kubernetes Service) cluster Configuration

# STEP 1.1 Create eks cluster without node group
eksctl create cluster --name=eks-cluster --region=ap-south-1 --zones=ap-south-1a,ap-south-1b --without-nodegroup

# STEP 1.2 To assign IAM role to cluster
eksctl utils associate-iam-oidc-provider --region=ap-south-1 --cluster eks-cluster --approve

# STEP 1.3 Create nodegroup
eksctl create nodegroup --cluster=eks-cluster --region=ap-south-1 --name=eks-node-group --node-type=c7i-flex.large --nodes=3 --nodes-min=2 --nodes-max=4 --node-volume-size=20 --ssh-access --ssh-public-key=kops-mum --managed --asg-access --external-dns-access --full-ecr-access --appmesh-access --alb-ingress-access

# --ssh-public-key should be available in region seleted above and closter, nodegroup should be in same region.

# STEP 1.4 update command to select the working cluster
aws eks update-kubeconfig --name eks-cluster --region=ap-south-1