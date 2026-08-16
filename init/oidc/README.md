# oidc

환경(dev/stage/prod, 각각 다른 AWS 계정)마다 한 번씩 적용하는 GitHub Actions OIDC 연동 모듈입니다. `init/bootstrap`/`init/connection`과 같은 성격 — 사람이 계정별로 수동 실행하는 1회성 구성입니다.

## 하는 일

- 해당 AWS 계정에 GitHub Actions OIDC Provider(`token.actions.githubusercontent.com`)를 등록
- `gha-<environment>-plan` role: `terraform plan`용, `ReadOnlyAccess`만 (실제 배포 리소스를 읽기 위함)
- `gha-<environment>-apply` role: `terraform apply`용, EC2/ALB/Route53 쓰기 권한

이 두 role은 **배포 대상 리소스(EC2/ALB/Route53 등) 권한만** 가지고 있고, Terraform state(S3) 접근 권한은 없습니다. state 버킷은 `init/runner`의 CodeBuild role(중앙 계정, 같은 계정이라 별도 cross-account 설정 불필요)이 담당합니다 — 그래서 워크플로우 job 안에서 이 role은 `provider "aws" { assume_role_with_web_identity {...} }`로만 assume되고, `terraform init`(backend)에는 관여하지 않습니다.

두 role의 신뢰 정책은 GitHub OIDC 토큰의 `sub` claim을 **GitHub Environment 이름**까지 스코핑합니다(`repo:<org>/<repo>:environment:<environment>-plan` / `...-apply`). 그래서 plan 게이트만 통과한 job이 apply role을 assume할 수 없습니다.

## 왜 backend key가 versions.tf에 없는가

이 모듈은 코드 하나로 여러 계정(dev/stage/prod)에 반복 적용됩니다. backend 블록은 변수를 쓸 수 없어서 `key`를 환경마다 다르게 하려면 partial configuration이 필요합니다:

```bash
cd init/oidc
terraform init -backend-config="key=oidc/dev/terraform.tfstate"
```

## 사용법 (환경 하나 추가할 때마다 반복)

```bash
cd init/oidc
terraform init -backend-config="key=oidc/dev/terraform.tfstate" -reconfigure
terraform apply \
  -var="environment=dev" \
  -var="env_aws_profile=dev-account" \
  -var="github_org=<github-org-or-user>" \
  -var="github_repo=<repo-name>"
```

apply 후 나온 두 role ARN(`plan_role_arn`, `apply_role_arn`)을 repo의 `ENV_ACCOUNT_IDS`/워크플로우가 조합할 수 있게 해당 계정 ID를 GitHub repo variable에 등록하세요 (`init/bootstrap`은 건드릴 필요 없습니다 - state 버킷 접근은 `init/runner`가 전담).

## GitHub 쪽 수동 설정

repo **Settings → Environments**에 다음을 생성하세요 (환경마다):
- `<environment>-plan` — required reviewers 없음 (PR plan job이 사용)
- `<environment>-apply-approval` — required reviewers 설정 (최종 승인 게이트)
- `<environment>-apply` — required reviewers 없음, "Deployment branches: main only"만 설정 (merge 후 apply job이 사용)

그리고 전역 `test-approval` 환경 하나(required reviewers 설정)를 별도로 만들어야 합니다.

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
