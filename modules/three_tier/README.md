# three_tier

bastion + web + WAS + DB, 4대짜리 3-tier EC2 구성을 한번에 묶어서 호출하는 module입니다. 내부적으로 `modules/compute`를 4번 호출합니다 (`module.bastion`, `module.web_server`, `module.was_server`, `module.db_server`).

## `modules/network` 의존성

이 module도 자체 서브넷/보안그룹을 만들지 않습니다. 호출하는 root(`env/*`)가 `module "network"`의 output을 각 티어에 맞게 넘겨줘야 합니다:
- bastion: `subnet_id` ← public 서브넷, `security_group_id` ← `bastion_security_group_id`
- web_server: `subnet_id` ← private 서브넷, `security_group_id` ← `web_security_group_id`
- was_server: `subnet_id` ← private 서브넷, `security_group_id` ← `internal_api_security_group_id`
- db_server: `subnet_id` ← private 서브넷, `security_group_id` ← `internal_mysql_security_group_id`

## user_data

`bastion_user_data`/`web_user_data`/`was_user_data`/`db_user_data`는 스크립트 내용(문자열)을 받습니다. 실제 스크립트 파일은 root가 소유하므로(예: `env/poc/scripts/`), 호출하는 쪽에서 `file("${path.module}/scripts/xxx.sh")`로 읽어서 넘겨주세요.

## 참고

이 module은 자체 provider나 backend를 설정하지 않습니다 — 이를 호출하는 root(`env/*`)가 provider/backend/버전 관리를 담당합니다.
