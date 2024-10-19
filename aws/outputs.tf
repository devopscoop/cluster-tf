# diff --color=always -w -y -W200 <(curl -sL https://raw.githubusercontent.com/aws-ia/terraform-aws-eks-blueprints/main/patterns/stateful/outputs.tf) outputs.tf | less -R

output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${local.region} update-kubeconfig --name ${module.eks.cluster_name} --user-alias ${module.eks.cluster_name}_${local.region}_${AWS_PROFILE} --alias ${module.eks.cluster_name}_${local.region}_${AWS_PROFILE}"
}
