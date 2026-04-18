############
# Provider #
############
variable "cloud_id" {
  type        = string
  default     = ""
}

variable "folder_id" {
  type        = string
  default     = ""
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
}

##############
variable "zones" {
  description = "Зоны доступности для подсетей и ВМ"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

variable "subnet_cidrs" {
  description = "CIDR блоки для подсетей"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
}

variable "master_count" {
  description = "Количество мастер-нод"
  type        = number
  default     = 3
}

variable "worker_count" {
  description = "Количество воркер-нод"
  type        = number
  default     = 3
}

variable "vm_resources" {
  description = "Вычислительные ресурсы для ВМ "
  type        = map(number)
  default = {
    cores         = 4
    memory        = 4
    core_fraction = 20
    disk_size     = 30
  }
}

variable "ssh_pub_key_path" {
  description = "Путь к публичному SSH ключу"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Путь к приватному SSH ключу "
  type        = string
  default     = "~/.ssh/id_ed25519"
}
variable "istio_node_port" {
  description = "NodePort, на котором Istio Ingress Gateway принимает трафик"
  type        = number
  default     = 30080
}

variable "k8s_api_port" {
  description = "Порт API сервера Kubernetes"
  type        = number
  default     = 6443
}

variable "registry_name" {
  type        = string
  default     = "netology-diplom-registry"
}

variable "sa_puller_id" {
  type        = string
  default     = ""
}

variable "existing_key_id" {
  type        = string
  default     = ""
}
variable "admin_ips" {
  description = "Список доверенных IP-адресов для доступа к SSH и Kube API"
  type        = list(string)
  default     = [""] 
}

variable "pod_network_cidr" {
  description = "CIDR сети подов"
  type        = string
  default     = "10.244.0.0/16" 
}

variable "service_network_cidr" {
  description = "CIDR сети сервисов"
  type        = string
  default     = "10.96.0.0/12" 
}
