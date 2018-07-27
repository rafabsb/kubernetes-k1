variable "data_fs" {
  type = "map"

  default = {
    name       = "ephemeral1"
    device     = "/dev/vdb"
    format     = "ext4"
    wipe       = "true"
    mount_path = "/var/lib/docker"
  }
}

variable "data_fs2" {
  type = "map"

  default = {
    name       = "ephemeral2"
    device     = "/dev/vdc"
    format     = "ext4"
    wipe       = "true"
    mount_path = "/var/lib/rancher"
  }
}

variable "data_fs3" {
  type = "map"

  default = {
    name       = "ephemeral3"
    device     = "/dev/vdd"
    format     = "ext4"
    wipe       = "true"
    mount_path = "/opt/rke"
  }
}

data "ignition_filesystem" "data_fs" {
  name = "ephemeral1"

  mount {
    device          = "${var.data_fs["device"]}"
    format          = "${var.data_fs["format"]}"
    wipe_filesystem = "${var.data_fs["wipe"]}"

    # create  = true
    # options = ["-L", "ROOT"]
  }
}

data "ignition_filesystem" "data_fs2" {
  name = "ephemeral2"

  mount {
    device          = "${var.data_fs2["device"]}"
    format          = "${var.data_fs2["format"]}"
    wipe_filesystem = "${var.data_fs2["wipe"]}"

    # create  = true
    # options = ["-L", "ROOT"]
  }
}

data "ignition_filesystem" "data_fs3" {
  name = "ephemeral3"

  mount {
    device          = "${var.data_fs3["device"]}"
    format          = "${var.data_fs3["format"]}"
    wipe_filesystem = "${var.data_fs3["wipe"]}"

    # create  = true
    # options = ["-L", "ROOT"]
  }
}

data "ignition_systemd_unit" "var_lib_docker_storage_mount" {
  name    = "var-lib-docker.mount"
  enabled = "true"

  content = <<EOF
    [Unit]
    Description=Mount ephemeral to ${var.data_fs["mount_path"]}
    Before=local-fs.target
    [Mount]
    What=${var.data_fs["device"]}
    Where=${var.data_fs["mount_path"]}
    Type=${var.data_fs["format"]}
    [Install]
    WantedBy=local-fs.target
EOF
}

data "ignition_systemd_unit" "var_lib_rancher_storage_mount" {
  name    = "var-lib-rancher.mount"
  enabled = "true"

  content = <<EOF
    [Unit]
    Description=Mount ephemeral to ${var.data_fs2["mount_path"]}
    Before=local-fs.target
    [Mount]
    What=${var.data_fs2["device"]}
    Where=${var.data_fs2["mount_path"]}
    Type=${var.data_fs2["format"]}
    [Install]
    WantedBy=local-fs.target
EOF
}

data "ignition_systemd_unit" "opt_rke_storage_mount" {
  name    = "opt-rke.mount"
  enabled = "true"

  content = <<EOF
    [Unit]
    Description=Mount ephemeral to ${var.data_fs3["mount_path"]}
    Before=local-fs.target
    [Mount]
    What=${var.data_fs3["device"]}
    Where=${var.data_fs3["mount_path"]}
    Type=${var.data_fs3["format"]}
    [Install]
    WantedBy=local-fs.target
  EOF
}
