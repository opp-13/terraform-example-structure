# NOTE: after `terraform apply`, open the AWS Console -> Developer Tools -> Settings -> Connections
# and complete the GitHub authorization handshake once. Terraform cannot finish this OAuth step;
# the connection stays in "PENDING" status until you do. Any consumer of this connection
# (CodeBuild webhooks, CodePipeline source actions) will fail with "Access denied to connection"
# until the handshake is complete. This is why the connection lives in its own module, separate
# from init/cicd: it's a one-time, manual-step prerequisite, not something a normal apply
# should ever need to redo.
resource "aws_codeconnections_connection" "github" {
  name          = "sesac-github"
  provider_type = "GitHub"
}
