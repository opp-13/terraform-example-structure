#!/bin/bash
set -euxo pipefail

# Amazon Linux 2023's default repos don't ship MySQL Server - add Oracle's official
# MySQL Yum repo first (EL9-compatible package, matches AL2023's dnf/glibc baseline).
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install -y https://dev.mysql.com/get/mysql84-community-release-el9-4.noarch.rpm
dnf install -y mysql-community-server

systemctl enable --now mysqld
