#!/bin/bash

# Функция для создания пользователя и привязки роли
create_user_with_role() {
  local USERNAME=$1
  local GROUP=$2
  local CLUSTER_ROLE=$3

  echo "Создаём пользователя $USERNAME (группа: $GROUP) с ролью $CLUSTER_ROLE..."

  # 1. Генерация сертификата
  openssl genrsa -out "$USERNAME.key" 2048
  openssl req -new -key "$USERNAME.key" -out "$USERNAME.csr" -subj "/CN=$USERNAME/O=$GROUP"
  openssl x509 -req -in "$USERNAME.csr" -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out "$USERNAME.crt" -days 365

  # 2. Добавление пользователя в kubectl config
  kubectl config set-credentials "$USERNAME" \
    --client-certificate="$USERNAME.crt" \
    --client-key="$USERNAME.key"

  kubectl config set-context "${USERNAME}-context" \
    --cluster=minikube --user="$USERNAME"

  # 3. Привязка ClusterRole к пользователю через ClusterRoleBinding
  kubectl create clusterrolebinding "${USERNAME}-${CLUSTER_ROLE}-binding" \
    --clusterrole="$CLUSTER_ROLE" \
    --user="$USERNAME"

  echo "Пользователь $USERNAME создан и привязан к роли $CLUSTER_ROLE!"
  echo "Для входа используйте: kubectl use-context ${USERNAME}-context"
}

# --- Создаём пользователей и назначаем роли ---

# Администратор (полный доступ + RBAC)
create_user_with_role "admin" "dev-team" "dev_admin"

# DevOps-инженер (без RBAC)
create_user_with_role "devops" "dev-team" "dev_ops"

# Разработчики (только чтение)
create_user_with_role "developer" "viewer" "viewer"

# Администратор секретов
create_user_with_role "secret-admin" "security" "secret_admin"
