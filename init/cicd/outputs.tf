output "lint_network_project_name" {
  description = "CodeBuild project that lints dmz/network - invoked as a stage within network_deploy"
  value       = aws_codebuild_project.lint_network.name
}

output "lint_compute_project_name" {
  description = "CodeBuild project that lints dmz/compute - invoked as a stage within compute_deploy"
  value       = aws_codebuild_project.lint_compute.name
}

output "pipeline_name" {
  description = "CodePipeline that plans/applies dmz/network on merges to the deploy branch"
  value       = aws_codepipeline.network_deploy.name
}

output "compute_pipeline_name" {
  description = "CodePipeline that plans/applies dmz/compute on merges to the deploy branch"
  value       = aws_codepipeline.compute_deploy.name
}

output "pipeline_artifact_bucket" {
  description = "S3 bucket used for CodePipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.id
}
