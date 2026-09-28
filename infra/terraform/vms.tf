data "yandex_compute_image" "coi" {
  family = "container-optimized-image"
}

data "yandex_compute_image" "alma" {
  family = "almalinux-8"
}

locals {
  # На nexus ставим python3.11: системный 3.6 в AlmaLinux 8 слишком стар для ansible-core
  cloud_init = { for k in keys(var.vms) : k => templatefile("${path.module}/templates/cloud-init.yml.tftpl", {
    user     = var.ssh_user
    ssh_key  = trimspace(file(var.ssh_public_key_file))
    packages = k == "nexus" ? ["python3.11"] : []
  }) }

  images = {
    teamcity-server = data.yandex_compute_image.coi.id
    teamcity-agent  = data.yandex_compute_image.coi.id
    nexus           = data.yandex_compute_image.alma.id
  }

  # Фиксированный внутренний адрес сервера — агенту он нужен в SERVER_URL
  server_ip = cidrhost(var.cidr[0], 10)
}

resource "yandex_compute_instance" "vm" {
  for_each = var.vms

  name        = each.key
  hostname    = each.key
  platform_id = "standard-v3"

  # смена ресурсов требует остановки ВМ
  allow_stopping_for_update = true

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = local.images[each.key]
      size     = each.value.disk_size
      type     = "network-hdd"
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.cicd.id
    ip_address         = each.key == "teamcity-server" ? local.server_ip : null
    nat                = true
    security_group_ids = [yandex_vpc_default_security_group.cicd.id]
  }

  metadata = merge(
    { user-data = local.cloud_init[each.key] },
    # Container Optimized Image сам поднимает docker-compose из метаданных
    each.key == "teamcity-server" ? {
      docker-compose = templatefile("${path.module}/templates/teamcity-server.yml.tftpl", {
        image = "${var.registry_mirror}/jetbrains/teamcity-server:${var.teamcity_version}"
      })
    } : {},
    each.key == "teamcity-agent" ? {
      docker-compose = templatefile("${path.module}/templates/teamcity-agent.yml.tftpl", {
        image      = "${var.registry_mirror}/jetbrains/teamcity-agent:${var.teamcity_version}"
        server_url = "http://${local.server_ip}:8111"
      })
    } : {},
  )
}
