# oidc

환경(dev/stage/prod, 각각 다른 AWS 계정)마다 한 번씩 적용하는 GitHub Actions OIDC 연동 모듈입니다. `init/bootstrap`/`init/connection`과 같은 성격 — 사람이 계정별로 수동 실행하는 1회성 구성입니다.

## 하는 일

- 해당 AWS 계정에 GitHub Actions OIDC Provider(`token.actions.githubusercontent.com`)를 등록
- `gha-<environment>-plan` role: `terraform plan`용, `ReadOnlyAccess`만 (실제 배포 리소스를 읽기 위함)
- `gha-<environment>-apply` role: `terraform apply`용, EC2/ALB/Route53 쓰기 권한

이 두 role은 **배포 대상 리소스(EC2/ALB/Route53 등) 권한만** 가지고 있고, Terraform state(S3) 접근 권한은 없습니다. state 버킷은 `init/runner`의 CodeBuild role(중앙 계정, 같은 계정이라 별도 cross-account 설정 불필요)이 담당합니다 — 그래서 워크플로우 job 안에서 이 role은 `provider "aws" { assume_role_with_web_identity {...} }`로만 assume되고, `terraform init`(backend)에는 관여하지 않습니다.

두 role의 신뢰 정책은 GitHub OIDC 토큰의 `sub` claim으로 스코핑합니다 — 단, **실제 토큰을 디코딩해서 확인한 진짜 값** 기준입니다. `plan`/`apply` job은 tfvars 값을 읽으려고 `environment: <env>`(순수 설정 저장용, protection rule 없음)를 선언하는데, GitHub는 job에 environment가 선언되어 있으면 `sub`를 `repo:...:environment:<name>` 형태로 만듭니다. 그리고 이 repo는 GitHub의 최신 "immutable subject claims" 형식이라 `repo:<org>@<owner_id>/<repo>@<repo_id>:environment:<name>`처럼 org/repo 이름 뒤에 `@<고유ID>`가 붙습니다 — 그 ID 부분은 계정마다 고정이지만 하드코딩하지 않으려고 와일드카드로 처리했습니다.

**`job_workflow_ref`(어느 워크플로우 파일에서 실행됐는지) claim으로 plan/apply를 구분하려는 시도는 실패했습니다** — 디코딩한 토큰의 `job_workflow_ref` 값이 trust policy 조건과 정확히 일치하는데도 `AssumeRoleWithWebIdentity`가 계속 거부됐고, 원인을 더 못 찾아서 포기했습니다. 그 결과 지금은 `plan`/`apply` 두 role의 신뢰 조건이 **동일합니다** (`environment: <env>`를 둘 다 쓰니까) — OIDC 레벨에서 "plan 권한으로는 apply role을 절대 못 가져간다"는 보장은 없고, 각 job이 어떤 role ARN을 요청할지 워크플로우 코드에 하드코딩되어 있는 것만으로 구분됩니다.

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

`<env>-plan`/`<env>-apply`처럼 role 종류별로 나눈 Environment는 필요 없습니다 — 대신 위에서 설명한 대로 plan/apply role의 신뢰 조건이 동일해지는 트레이드오프를 감수합니다.

**주의**: 이 레포가 immutable subject claims를 안 쓴다면(또는 GitHub가 나중에 형식을 또 바꾸면) `sub` 값이 달라질 수 있습니다. 새 환경 추가하거나 `AssumeRoleWithWebIdentity`가 이유 없이 막히면, `.github/workflows/terraform-pr.yml`의 "Get GitHub OIDC token for AWS" 스텝에 있던 디버그 코드(`core.info(JSON.stringify(payload))`, 지금은 주석 처리/제거되어 있을 수 있음)를 다시 넣어서 실제 `sub` 값부터 확인하세요 — 일반론으로 추측하지 말고요.

`bastion_ssh_cidr`/`AWS_ACCOUNT_ID`가 Secret이어도, PR 코멘트로 올라가는 plan 결과 자체는 `.github/workflows/terraform-pr.yml`이 파일을 읽어서 API로 직접 올리는 거라 GitHub의 자동 마스킹을 안 탑니다 — 그래서 워크플로우 안에 이 두 값을 명시적으로 치환(redact)하는 코드가 따로 있습니다. 값을 더 가리고 싶으면 그 redaction 배열에 추가하세요.

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
