# oidc

환경(dev/stage/prod, 각각 다른 AWS 계정)마다 한 번씩 적용하는 GitHub Actions OIDC 연동 모듈입니다. `init/bootstrap`/`init/connection`과 같은 성격 — 사람이 계정별로 수동 실행하는 1회성 구성입니다.

## 하는 일

- 해당 AWS 계정에 GitHub Actions OIDC Provider(`token.actions.githubusercontent.com`)를 등록
- `gha-<environment>-plan` role: `terraform plan`용, `ReadOnlyAccess`만 (실제 배포 리소스를 읽기 위함)
- `gha-<environment>-apply` role: `terraform apply`용, EC2/ALB/Route53 쓰기 권한

이 두 role은 **배포 대상 리소스(EC2/ALB/Route53 등) 권한만** 가지고 있고, Terraform state(S3) 접근 권한은 없습니다. state 버킷은 `init/runner`의 CodeBuild role(중앙 계정, 같은 계정이라 별도 cross-account 설정 불필요)이 담당합니다 — 그래서 워크플로우 job 안에서 이 role은 `provider "aws" { assume_role_with_web_identity {...} }`로만 assume되고, `terraform init`(backend)에는 관여하지 않습니다.

두 role의 신뢰 정책은 GitHub OIDC 토큰의 `sub` claim을 **`pull_request`(plan) / `ref:refs/heads/main`(apply)** 로 스코핑합니다 — GitHub Environment 이름이 아닙니다. `plan`/`apply` job은 `environment: <env>`(순수 설정 저장용, protection rule 없음)를 선언하지만 이건 tfvars 값을 담아두는 컨테이너일 뿐이고, 실제 신뢰 경계는 이 claim 모양(PR에서 도는 job인지, main push apply job인지)과 AWS 계정 자체입니다. 그래서 환경 하나 늘어도 `<env>-plan`/`<env>-apply` 같은 별도 Environment를 안 만들어도 됩니다.

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

apply 후 나온 두 role ARN(`plan_role_arn`, `apply_role_arn`)에서 계정 ID만 뽑아서 아래 GitHub Environment secret에 등록하세요.

## GitHub 쪽 수동 설정

repo **Settings → Environments**에 다음을 생성하세요:

- **`test-approval`** (전역, 환경 무관 하나만) — Required reviewers 설정. PR의 첫 승인 게이트.
- **`<env>`** (환경마다, 예: `poc`) — protection rule 없음, 순수 설정 저장용. `plan`/`apply` job이 여기서 tfvars 값을 읽습니다:
  - **Variables**: `PROJECT`, `OWNER`, `ZONE`, `ENVIRONMENT`, `REGION`, `VPC_CIDR`, `AZS`(예: `["ap-northeast-2a","ap-northeast-2c"]`), `PUBLIC_SUBNET_CIDRS`, `PRIVATE_SUBNETS`(JSON, 예: `[{"name":"frontend-a","cidr":"10.0.2.0/24"}, ...]`) — 민감하지 않은 값
  - **Secrets**: `BASTION_SSH_CIDR`, `AWS_ACCOUNT_ID`(이 환경의 계정 ID) — 로그에서 가려야 하는 값. **반드시 Secret으로 등록하세요, Variable로 등록하면 Actions 로그(명령어 echo 등)에 그대로 노출됩니다** (Variable은 마스킹 대상이 아님).
- **`<env>-apply-approval`** (환경마다) — Required reviewers 설정. 최종 승인 게이트.

`<env>-plan`/`<env>-apply`처럼 role 종류별로 나눈 Environment는 필요 없습니다 — OIDC 신뢰 조건이 이제 GitHub Environment 이름이 아니라 `pull_request`/`ref:refs/heads/main` claim으로 스코핑되기 때문입니다.

`bastion_ssh_cidr`/`AWS_ACCOUNT_ID`가 Secret이어도, PR 코멘트로 올라가는 plan 결과 자체는 `.github/workflows/terraform-pr.yml`이 파일을 읽어서 API로 직접 올리는 거라 GitHub의 자동 마스킹을 안 탑니다 — 그래서 워크플로우 안에 이 두 값을 명시적으로 치환(redact)하는 코드가 따로 있습니다. 값을 더 가리고 싶으면 그 redaction 배열에 추가하세요.

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
