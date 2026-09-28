output "teamcity_url" {
  value = "http://${yandex_compute_instance.vm["teamcity-server"].network_interface[0].nat_ip_address}:8111"
}

output "nexus_url" {
  value = "http://${yandex_compute_instance.vm["nexus"].network_interface[0].nat_ip_address}:8081"
}

output "vms" {
  value = { for k, v in yandex_compute_instance.vm : k => {
    external = v.network_interface[0].nat_ip_address
    internal = v.network_interface[0].ip_address
  } }
}

# Инвентори для плейбука Nexus из задания
resource "local_file" "inventory" {
  filename = "${path.module}/../infrastructure/inventory/cicd/hosts.yml"
  content = templatefile("${path.module}/templates/hosts.yml.tftpl", {
    host = yandex_compute_instance.vm["nexus"].network_interface[0].nat_ip_address
    user = var.ssh_user
  })
}
