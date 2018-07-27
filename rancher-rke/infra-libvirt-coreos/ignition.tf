# asd

data "ignition_systemd_unit" "docker_service_config" {
  name = "docker.service"

  dropin = [
    {
      name = "10-wait-docker.conf"

      content = <<EOF
        [Unit]
        After=var-lib-docker.mount
        Requires=var-lib-docker.mount
EOF
    },
    {
      name = "20-http-proxy.conf"

      content = <<EOF
        [Service]
        Environment="HTTP_PROXY=http://192.168.8.1:3128"
        Environment="HTTPS_PROXY=http://192.168.8.1:3128"
        Environment="NO_PROXY=localhost,127.0.0.1,192.168.8.1,192.168.0.0/16,10.43.0.0/16,rafabsb.me,bb.com.br"
EOF
    },
  ]
}

data "ignition_file" "hostname" {
  count      = "${var.qtd_vms}"
  filesystem = "root"
  path       = "/etc/hostname"
  mode       = "0644"

  content {
    content = "${var.vm_hostname}${count.index}"
  }
}

data "ignition_file" "torcx1" {
  filesystem = "root"
  path       = "/etc/torcx/next-profile"
  mode       = "0644"

  content {
    content = "docker"
  }
}

data "ignition_file" "torcx2" {
  filesystem = "root"
  path       = "/var/lib/torcx/store/1745.7.0/docker:17.03.torcx.tgz"
  mode       = "0644"

  source {
    source       = "http://192.168.5.1:8080/Downloads/docker_17.03.torcx.tgz"
    verification = "sha512-7ed8024f8352c51aac86c9ecfad2c1133caf72fab7e42e120896c1d9b7842f490fe28be1f172f963891cbfa533cc3f3ec0df576b6fc939b2eba258f5421ff41e"
  }
}

data "ignition_file" "torcx3" {
  filesystem = "root"
  path       = "/etc/torcx/profiles/docker.json"
  mode       = "0644"

  content {
    content = <<EOF
    {
      "kind": "profile-manifest-v0",
      "value": {
        "images": [
          {
            "name": "docker",
            "reference": "17.03"
          }
        ]
      }
    }
EOF
  }
}

data "ignition_file" "docker_daemon" {
  filesystem = "root"
  path       = "/etc/docker/daemon.json"
  mode       = "0644"

  content {
    content = "${var.docker_daemon_json}"
  }
}

data "ignition_file" "sysctl_config" {
  filesystem = "root"
  path       = "/etc/sysctl.conf"
  mode       = "0644"

  content {
    content = <<EOF
    vm.max_map_count=262144
EOF
  }
}

data "ignition_networkd_unit" "example" {
  count = "${var.qtd_vms}"
  name  = "00-eth0.network"

  content = <<EOF
[Match]
Name=eth0

[Network]
${var.virtual_machine_dns_servers}
Address=${element(var.vm_ips, count.index)}
Gateway=${var.virtual_machine_gateway}
EOF
}

data "ignition_systemd_unit" "example" {
  name = "example.service"

  content = <<EOF
    [Service]
    Type=oneshot
    ExecStart=/usr/bin/echo Hello World

    [Install]
    WantedBy=multi-user.target
EOF
}

data "template_file" "example_service_unit_content" {
  template = "${file("${path.module}/files/ovf-example.service.tpl")}"

  vars = {
    service_directory  = "${var.service_directory}"
    server_binary_name = "${var.server_binary_name}"
    service_user       = "${var.service_user}"
  }
}

########################################################################

# tls random key for root auto access to configure
resource "tls_private_key" "example_provisioning_ssh_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

data "ignition_user" "root_user" {
  name                = "root"
  ssh_authorized_keys = ["${var.management_ssh_keys}"]

  # ssh_authorized_keys = ["${tls_private_key.example_provisioning_ssh_key.public_key_openssh}"]
  password_hash = "$1$xyz$5g8MbFX.qpsReBdkZF5st1"
}

data "ignition_user" "core_user" {
  name                = "core"
  ssh_authorized_keys = ["${var.management_ssh_keys}"]
  password_hash       = "$1$xyz$5g8MbFX.qpsReBdkZF5st1"
}

data "ignition_user" "example_service_user" {
  name     = "${var.service_user}"
  home_dir = "${var.service_directory}"
}

data "ignition_config" "example" {
  count = "${var.qtd_vms}"

  systemd = [
    "${data.ignition_systemd_unit.example.id}",
    "${data.ignition_systemd_unit.docker_service_config.id}",
    "${data.ignition_systemd_unit.var_lib_docker_storage_mount.id}",
    "${data.ignition_systemd_unit.var_lib_rancher_storage_mount.id}",
    "${data.ignition_systemd_unit.opt_rke_storage_mount.id}",
  ]

  networkd = ["${data.ignition_networkd_unit.example.*.id[count.index]}"]

  users = [
    "${data.ignition_user.root_user.id}",
    "${data.ignition_user.core_user.id}",
    "${data.ignition_user.example_service_user.id}",
  ]

  files = [
    "${data.ignition_file.torcx1.id}",
    "${data.ignition_file.torcx2.id}",
    "${data.ignition_file.torcx3.id}",
    "${data.ignition_file.docker_daemon.id}",
    "${data.ignition_file.hostname.*.id[count.index]}",
    "${data.ignition_file.sysctl_config.id}",
  ]

  filesystems = [
    "${data.ignition_filesystem.data_fs.id}",
    "${data.ignition_filesystem.data_fs2.id}",
    "${data.ignition_filesystem.data_fs3.id}",
  ]
}

resource "libvirt_ignition" "ignition" {
  count   = "${var.qtd_vms}"
  name    = "ignition-${count.index}"
  content = "${data.ignition_config.example.*.rendered[count.index]}"
}
