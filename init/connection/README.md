# connection

GitHub CodeConnections 연결 하나만 만드는 최소 모듈입니다. `init/bootstrap`(state 버킷)과 같은 성격 — apply 후 **콘솔에서 사람이 수동으로 인증을 완료해야 하는 1회성 사전 준비 단계**라서 `init/cicd`와 분리했습니다.

이 리소스를 `init/cicd`와 같은 모듈에 두면, `init/cicd`를 한 번에 apply할 때 아직 인증이 안 끝난 connection을 CodeBuild webhook/CodePipeline이 바로 쓰려고 하다가 `Access denied to connection` 에러로 실패합니다. 분리해두면 이 모듈만 먼저 apply하고 인증을 끝낸 뒤 `init/cicd`를 apply하면 되므로 중간에 실패할 일이 없습니다.

## 사용법

```bash
cd init/connection
terraform init
terraform apply
```

apply 후 **AWS 콘솔 → Developer Tools → Settings → Connections**에서 `sesac-github` 항목을 찾아 **Update pending connection**으로 GitHub 인증을 완료하세요. 상태가 `PENDING` → `AVAILABLE`로 바뀌어야 합니다.

GitHub에서 (개인 계정 또는 opp-13 조직) Settings → Applications → Installed GitHub Apps로 이동
AWS Connector for GitHub 앱 찾아서 Configure 클릭
- Repository access에서 원하는 레포가 포함되어 있는지 확인
- request 된 Permission이 승인되었는지 확인

```bash
terraform apply -refresh-only
terraform output connection_status  # AVAILABLE이 나올 때까지 확인
```

그다음 `init/cicd`를 apply할 때 이 모듈의 output을 그대로 넘겨주세요:

```bash
cd ../cicd
terraform init
terraform apply \
  -var="github_repo_owner=opp-13" \
  -var="codeconnections_arn=$(terraform output -raw connection_arn -chdir=../connection)"
```

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
