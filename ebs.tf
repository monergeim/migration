resource "aws_ebs_volume" "pv" {
  for_each = var.snaps
  availability_zone = "eu-west-2a"
  snapshot_id = each.key
  type = "gp2"

  tags = {
    Name = "kuber-${each.value["pv"]}"
    "kubernetes.io/created-for/pv/name" = each.value["pv"]
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/created-for/pvc/name" = each.value["pvc"]
    "kubernetes.io/created-for/pvc/namespace" = var.ns
    "app" = each.value["app"]
  }
}


resource "kubernetes_persistent_volume" "pv" {
  for_each = aws_ebs_volume.pv
  metadata {
    name =  lookup(each.value["tags"], "kubernetes.io/created-for/pv/name")
    labels = {
      app = lookup(each.value["tags"], "app")
      namespace = var.ns
    }
    annotations = {
      pvc = lookup(each.value["tags"], "kubernetes.io/created-for/pvc/name")
    }
  }
  spec {
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "failure-domain.beta.kubernetes.io/zone"
            operator = "In"
            values = ["eu-west-2a"]
          }
          match_expressions {
            key = "failure-domain.beta.kubernetes.io/region"
            operator = "In"
            values = ["eu-west-2"]
          }
        }
      }
    }
    capacity = {
      storage = "1Gi"
    }
    volume_mode = "Filesystem"
    storage_class_name = "aws-retain"
    access_modes = ["ReadWriteOnce"]
    persistent_volume_source {
      aws_elastic_block_store {
        fs_type = "ext4"
        volume_id = each.value["id"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "pv" {
  for_each = kubernetes_persistent_volume.pv
  metadata {
    name = kubernetes_persistent_volume.pv[each.key].metadata.0.annotations.pvc
    namespace = kubernetes_persistent_volume.pv[each.key].metadata.0.labels.namespace
    labels = {
      app = kubernetes_persistent_volume.pv[each.key].metadata.0.labels.app
    }
  }
  spec {
    storage_class_name = "aws-retain"
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.pv[each.key].metadata.0.name
  }
}
