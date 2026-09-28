resource "yandex_vpc_network" "cicd" {
  name = "cicd"
}

resource "yandex_vpc_subnet" "cicd" {
  name           = "cicd"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.cicd.id
  v4_cidr_blocks = var.cidr
}

# Группа по умолчанию у новой сети режет входящие — описываем её явно
resource "yandex_vpc_default_security_group" "cicd" {
  network_id = yandex_vpc_network.cicd.id

  dynamic "ingress" {
    for_each = var.public_ports
    content {
      protocol       = "TCP"
      port           = ingress.value
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    protocol          = "ANY"
    description       = "трафик внутри группы (агент -> сервер, агент -> nexus)"
    predefined_target = "self_security_group"
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
