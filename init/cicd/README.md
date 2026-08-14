# cicd

`dmz/network`/`dmz/compute` 배포 파이프라인(CodePipeline: Source → Lint → Plan → 수동 승인 → Apply)을 관리하는 root module입니다.

## 구조

- **GitHub 연동**: 이 모듈은 connection을 직접 만들지 않고, `init/connection`이 만든 것을 `var.codeconnections_arn`으로 받아서 씁니다. connection은 apply 후 콘솔에서 사람이 인증을 완료해야 하는 1회성 수동 단계라, 그런 리소스를 이 모듈 안에 같이 두면 아직 인증이 안 끝난 connection을 바로 쓰려다 `Access denied to connection` 에러로 apply가 실패합니다. 그래서 별도 모듈로 분리했습니다 — 자세한 이유와 사용법은 [`../connection/README.md`](../connection/README.md) 참고.
- **Lint** (`sesac-lint-network`, `sesac-lint-compute` CodeBuild project): 독립된 PR 트리거 파이프라인이 아니라, 아래 두 배포 파이프라인 각각의 **Source 다음 스테이지**로 들어가 있습니다. 같은 `buildspec.yml`을 재사용하지만 `LINT_DIRS` 환경변수를 CodeBuild project 레벨에서 각자 다르게 override해서, `network_deploy`는 `dmz/network`만, `compute_deploy`는 `dmz/compute`만 lint합니다 — 레이어별로 분리하지 않으면 `dmz/compute`가 깨진 상태일 때 `dmz/network`만 고친 배포까지 Lint 단계에서 같이 막혀버립니다. `terraform fmt -check`/`validate`/`tflint`/`checkov`를 돌리고, 실패하면 그 자리에서 파이프라인이 멈춰 Plan/Apply로 넘어가지 않습니다 — "린트를 통과해야 배포된다"가 기술적으로 강제됩니다.

  (참고: 처음엔 독립된 `aws_codebuild_webhook` + CODECONNECTIONS 인증으로 구현했으나, IAM/connection/GitHub App 설정을 다 맞춰도 `Access denied to connection`이 계속 발생하는 해결 안 된 이슈였습니다. 그 다음엔 PR 트리거용 독립 `sesac-lint` CodePipeline으로 옮겼다가, 배포 파이프라인 안에 레이어별 Lint 스테이지를 넣으면서 최종적으로 제거했습니다.)

- **배포 파이프라인** (`sesac-network-deploy`(dmz/network), `sesac-compute-deploy`(dmz/compute) CodePipeline, 둘 다 V2): `main` 브랜치에 각 레이어 경로(`dmz/network/**` / `dmz/compute/**`) 변경이 머지되면 그 파이프라인만 자동으로 시작됩니다 (`trigger.git_configuration.push.file_paths`로 필터링 — 서로 무관한 변경에 둘 다 도는 걸 방지).
  1. **Source**: GitHub에서 코드 가져오기
  2. **Lint**: 해당 레이어 전용 CodeBuild project로 fmt/validate/tflint/checkov — 실패하면 여기서 중단
  3. **Plan**: `ReadOnlyAccess` 권한만 가진 role로 `terraform plan` 실행, 결과를 아티팩트로 저장
  4. **Approval**: 담당자가 콘솔에서 Plan 단계 로그(plan 결과)를 확인하고 수동 승인
  5. **Apply**: 해당 레이어가 다루는 리소스로만 한정된 role로 승인된 plan을 그대로 apply

  두 파이프라인 모두 `execution_mode = "QUEUED"`입니다. 기본값(SUPERSEDED)은 최신 실행이 오래된 실행을 앞질러 건너뛸 수 있어서, 오래된 실행의 plan이 그 사이 바뀐 state에 더 이상 맞지 않아 apply가 거부되는 "Saved plan is stale" 에러가 실제로 발생했습니다. QUEUED는 실행을 항상 하나씩 순서대로 진행시켜 이 문제를 막습니다.

`dmz/network`, `dmz/compute` 두 레이어를 대상으로 합니다. `init/bootstrap`, `init/connection`, `init/cicd` 자신은 자주 바뀌지 않는 메타 레이어라 계속 로컬에서 수동 apply합니다. 다른 레이어(예: `database`)가 추가되면 이 모듈의 plan/apply role, CodeBuild project, pipeline 패턴(그리고 `buildspec-plan.yml`/`buildspec-apply.yml`을 그대로 재사용하면서 `TF_MODULE_PATH` 환경변수만 CodeBuild project 레벨에서 override하는 방식)을 그대로 복제해서 확장하세요.

## 사전 준비

1. `init/bootstrap`이 먼저 apply되어 있어야 합니다 (`terraform-state-sesac` 버킷 필요).
2. `init/connection`을 먼저 apply하고, 콘솔에서 CodeConnections 핸드셰이크를 완료해 상태가 `AVAILABLE`이 된 것을 확인하세요.
3. `dmz/network`가 먼저 apply되어 있어야 합니다 (`dmz/compute`가 그 output을 `terraform_remote_state`로 참조).
4. 그 다음에만 이 모듈을 apply합니다:

```bash
cd init/cicd
terraform init
terraform apply \
  -var="github_repo_owner=opp-13" \
  -var="codeconnections_arn=$(terraform -chdir=../connection output -raw connection_arn)"
```

별도로 GitHub Webhooks를 수동 등록할 필요는 없습니다 — merge 트리거는 각 배포 파이프라인의 `trigger` 설정이 자동으로 처리합니다.

## Dry run

각 배포 파이프라인의 Plan 단계가 해당 레이어의 공식 dry run 지점입니다. 로컬에서 `terraform plan`을 미리 돌려보는 것도 가능하지만(공유 backend의 S3 네이티브 락이 보호), 실제 배포 승인은 파이프라인의 Manual Approval에서만 이루어집니다.

## 자동 생성 문서

아래는 pre-commit의 `terraform-docs` 훅이 커밋마다 자동으로 갱신합니다 (Requirements/Providers/Resources/Inputs/Outputs). 이 마커 밖의 내용은 손대지 않습니다.

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
