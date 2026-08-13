# Terraform 연구


## 기본 설계 사상

환경별 공통 리소스 (vpc, subnet, nat, sg, instance set)는 modules에 정의

나머지는 따로따로 main.tf에 지정



