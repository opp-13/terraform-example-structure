# runner

AWS CodeBuild가 GitHub Actions self-hosted runner로 등록되는 인프라입니다. `init/bootstrap`/`init/connection`과 같은 성격의 1회성 meta 레이어 — 사람이 수동으로 apply하고, apply 후 몇 가지 수동 단계를 거쳐야 동작합니다.

## 동작 방식

```
GitHub webhook (workflow_job, action=queued)
        │  POST + X-Hub-Signature-256
        ▼
API Gateway (HTTP API) → Lambda(webhook) → CodeBuild StartBuild → 임시 runner 컨테이너
                                                                       │
                                                            config.sh --ephemeral → run.sh → 종료
```

CodeBuild의 네이티브 GitHub 웹훅은 `PUSH`/`PULL_REQUEST_*`만 지원하고 `workflow_job` 이벤트는 지원하지 않습니다. 그래서 Lambda + API Gateway가 웹훅을 받아 서명 검증 후 `codebuild:StartBuild`를 호출하는 구조가 필요합니다.

CodeBuild 빌드는 `actions/runner`를 다운로드하고, GitHub REST API로 등록 토큰을 발급받아 `--ephemeral`(1회용) 모드로 등록한 뒤 `run.sh`로 정확히 그 1개 job만 실행하고 사라집니다.

이 runner는 dev/stage/prod 전체가 공유하는 하나의 runner이자, Terraform state 버킷(`init/bootstrap`)과 **같은 중앙 계정**에 있습니다. 그래서 이 runner 자신의 role(`gha-runner`)에 state 버킷 S3 권한을 직접 줬습니다(`iam.tf`) — cross-account 버킷 정책 없이 같은 계정 IAM만으로 충분합니다. `terraform init`/backend 접근은 이 role의 ambient 자격증명(container credentials)으로 자동으로 처리되고, 워크플로우에서 별도로 assume할 필요가 없습니다.

반면 실제 배포 대상 리소스(EC2/ALB/Route53 등)는 각 환경마다 다른 AWS 계정에 있으므로, 그건 여전히 `init/oidc`가 만든 환경별 role을 job 안에서 GitHub OIDC로 assume해서 접근합니다(`provider "aws" { assume_role_with_web_identity {...} }`). 즉 **state는 runner의 중앙 role, 배포 리소스는 환경별 OIDC role** — 이렇게 분리한 이유는 이 runner가 모든 환경의 job을 다 처리하기 때문에, 배포 리소스 권한까지 runner 자신에게 주면 `dev` 게이트만 통과한 job이 `prod` 리소스를 건드릴 수 있게 되기 때문입니다. state는 이 위험이 없다고 판단해(같은 계정, 이미 공유 runner) 중앙 role로 단순화했습니다.

## 사용법

```bash
cd init/runner
terraform init
terraform apply \
  -var="github_org=<github-org-or-user>" \
  -var="github_repo=<repo-name>"
```

## apply 후 수동 단계 (사람이 해야 함)

1. **GitHub 인증 방식 선택** — 이 구성은 fine-grained PAT(레포 단위 `Administration: Read & write` 권한, registration-token 발급에 필요)를 MVP로 가정합니다. 여러 레포로 확장할 계획이면 GitHub App(짧은 수명의 installation token)이 더 적합하지만 buildspec/reaper 쪽에 JWT 서명·토큰 교환 코드가 추가로 필요합니다 — 지금은 단일 레포 기준으로 PAT를 채택했습니다.
2. PAT를 발급한 뒤, Terraform이 만든 빈 시크릿 컨테이너에 직접 채워 넣습니다(Terraform이 `secret_string`을 설정하지 않는 이유: PAT가 plan/state에 노출되면 안 되기 때문):
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id "$(terraform output -raw github_token_secret_name)" \
     --secret-string '{"token":"<fine-grained PAT>"}'
   ```
3. 출력값을 확인합니다:
   ```bash
   terraform output -raw webhook_url
   terraform output -raw webhook_hmac_secret
   ```
4. GitHub repo **Settings → Webhooks → Add webhook**:
   - Payload URL = 위 `webhook_url`
   - Content type = `application/json`
   - Secret = 위 `webhook_hmac_secret`
   - "Which events" → **Let me select individual events → Workflow jobs**만 체크 (Send me everything 금지 — 서명 검증은 되지만 불필요한 이벤트로 Lambda가 계속 호출됨)
5. Runner label 확인 — `var.runner_label`(기본값 `codebuild-ephemeral`)이 `.github/workflows/*.yml`의 `runs-on: [self-hosted, codebuild-ephemeral]`과 정확히 일치해야 합니다. 이 값은 이 모듈과 워크플로우 YAML 사이의 인터페이스 계약입니다.
6. GitHub 웹훅 화면의 **Recent Deliveries → Redeliver**로 왕복 확인 후, Lambda의 CloudWatch Logs와 CodeBuild 빌드 히스토리에서 실제 runner 등록/실행을 확인합니다.

## 알려진 리스크

- **Cold start**: CodeBuild 컴퓨트 프로비저닝 + 이미지 pull + runner tar 다운로드로 수십 초~수 분 소요될 수 있습니다. 개선이 필요하면 runner tar/terraform/awscli를 미리 구운 커스텀 ECR 이미지로 `var.runner_image`를 교체하세요.
- **중복 웹훅 배달**: GitHub는 최소 1회 배달을 보장(중복 가능)합니다. ephemeral runner는 1회용이라 중복 배달이 와도 두 번째 빌드는 이미 job이 잡힌 걸 확인하고 빠르게 종료됩니다 — 낭비는 있지만 안전합니다.
- **Orphan 등록**: 빌드가 `build_timeout` 등으로 비정상 종료되면 runner 등록이 남을 수 있습니다. buildspec의 `post_build`가 1차 안전망이고, `gha-runner-reaper` Lambda(EventBridge 스케줄, 기본 30분마다)가 offline 상태의 `codebuild-*` runner를 찾아 삭제하는 2차 안전망입니다.
- **비용 가드레일**: `concurrent_build_limit`(`var.max_concurrent_runners`)로 동시 빌드 수를 제한합니다.

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
