terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">=1.5"
}

provider "yandex" {
  # token     = var.token
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.default_zone
  service_account_key_file = file("~/authorized_key.json")
}

# 1. Создаем сервисный аккаунт для Terraform
resource "yandex_iam_service_account" "sa_terraform" {
  name        = "sa-terraform"
  description = "Сервисный аккаунт для управления инфраструктурой через Terraform"
}

# 2. Выдаем ему права администратора на каталог (чтобы он мог создавать ВМ, сети и т.д.)
resource "yandex_resourcemanager_folder_iam_member" "sa_terraform_editor" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa_terraform.id}"
}

# 3. Создаем статические ключи доступа (Access Key / Secret Key) для работы с S3
resource "yandex_iam_service_account_static_access_key" "sa_terraform_static_key" {
  service_account_id = yandex_iam_service_account.sa_terraform.id
  description        = "Статический ключ для доступа Terraform к S3 бакету"
}

# 4. Создаем сам S3-бакет для хранения стейта
resource "yandex_storage_bucket" "tf_state_bucket" {
  bucket     = var.bucket_name
  access_key = yandex_iam_service_account_static_access_key.sa_terraform_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_terraform_static_key.secret_key

  # Включаем версионирование, чтобы можно было откатить сломанный стейт
  versioning {
    enabled = true
  }
}

# 5. Выводим ключи в консоль, чтобы вы могли скопировать их в основную папку
output "ACCESS_KEY" {
  value     = yandex_iam_service_account_static_access_key.sa_terraform_static_key.access_key
  sensitive = true
}

output "SECRET_KEY" {
  value     = yandex_iam_service_account_static_access_key.sa_terraform_static_key.secret_key
  sensitive = true
}
