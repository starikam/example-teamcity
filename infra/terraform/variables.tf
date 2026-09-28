variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "cidr" {
  type    = list(string)
  default = ["10.10.1.0/24"]
}

variable "ssh_user" {
  type        = string
  default     = "yc-user"
  description = "Пользователь, которого cloud-init создаёт на всех ВМ"
}

variable "ssh_public_key_file" {
  type    = string
  default = "~/.ssh/yc_hw.pub"
}

# Docker Hub из РФ недоступен — образы тянем через зеркало.
# dockerhub.timeweb.cloud отдавал тяжёлые слои TeamCity на ~200 КБ/с,
# mirror.gcr.io из Yandex Cloud — ~7 МБ/с.
variable "registry_mirror" {
  type    = string
  default = "mirror.gcr.io"
}

variable "teamcity_version" {
  type    = string
  default = "2026.1.3"
}

# Параметры ВМ по заданию: сервер 4CPU/4RAM, агент и nexus 2CPU/4RAM
variable "vms" {
  type = map(object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
  }))
  default = {
    teamcity-server = { cores = 4, memory = 4, core_fraction = 100, disk_size = 30 }
    teamcity-agent  = { cores = 2, memory = 4, core_fraction = 20, disk_size = 30 }
    nexus           = { cores = 2, memory = 4, core_fraction = 20, disk_size = 20 }
  }
}

variable "public_ports" {
  type        = list(number)
  default     = [22, 8081, 8111]
  description = "ssh, nexus, teamcity"
}
