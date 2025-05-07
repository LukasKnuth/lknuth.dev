---
title: "Tiny reliability setup"
date: 2024-01-06T14:23:13+01:00
---

- how my apps all run on ephemeral storage
- how that storage is SQLite and how its replicated off-site with Litestream - continously
- how that process is montiored by fluentbit logs and gotify notifications
- add a new chaos engineering task that kills deployments every week friday at random time in the night.
  - validates regularly that my backups are in-tact and working
  - validates restore works regularly

- What are some challanges of this?
  - service must use sqlite
  - inappropriate timing could lead to data loss
  - no immediate feedback when using the application (data can still always be written locally.)

----

About a year ago, I rebuild my home server.
It still runs on Kubernetes, but I moved away from traditional tooling associated with it.
The goal was simplification.

I applied the same goal to my reliability setup.
I had a look at what large deployments usually ship with: Prometheus, Grafana and the likes.
The main problem with all of these is that there are many moving pieces and those all want a piece of the (very limited) resource pie.
I run the entire server on a single Raspberry Pi.

## Data Durability
(whats a good word for this? "Reliability of data" or "Availablity" or "fault tolerance" or something?)

I wanted my data to be safe from failures.
After all, I'm running the server off of an SD Card that could be corrupted at any point.

I started off with a simple CRON backup job that runs daily.
And then I thought "do I want to lose a whole day worth of data?".

Another issue in Kubernetes is that if a workload requires a persistent storage, that storage becomes co-located with the workload.
This isn't a problem in my current deployment where I only have a single node in my cluster.
The other issue associated with persistent storage is that you tend to think its more durable than it really is.

"If you don't know if your backup works, you don't have a backup" as the common wisdom goes.
So what if I could solve both problems with a single solution: my backups would be continuous and all storage in the cluster ephemeral.

> ![tip]
> **Ephemeral** in this context means the storage will be cleared every time the `Deployment` is started.
> Kubernetes implements this by creating a new temporary directory on the host and mounting it into the containers on each start.

To this end, I picked Litestream for SQLite.
It can run as a sidecar container to the actual application and just needs access to the SQLite database file on disk.
We can achieve both easily by sharing an `emptyDir` between the two containers:

```terraform
resource "kubernetes_deployment" "app" {
  metadata {
    name = var.app_name
  }

  spec {
    template {
      metadata {}
      spec {
        volume {
          name = "application-state"
          emptyDir {}
        }

        container {
          name = "litestream-sidecar"
          image = ""
          args = ["replicate"]

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_replicate.file_path)
          }
        }

        container {
          name = "my-app"
          image = ""

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_replicate.file_path)
          }
        }
      }
    }
  }
```

Both the main application container and the litestream sidecar access the same ephemeral storage volume.
The `mount_path` above is configured as a parameter to the Terraform module.
We use the same parameter to create a `ConfigMap` that holds the configuration file for Litestream.

```terraform
resource "kubernetes_config_map_v1" "litestream_config" {
  metadata {
    name      = "${var.app_name}-litestream-config"
  }

  data = {
    "litestream.yml" = yamlencode({
      dbs = [{
        path = var.sqlite_replicate.file_path,
        replicas = [{
          type        = "s3"
          endpoint    = "my.local.minio"
          bucket      = "homeserver"
          path        = var.app_name
        }]
      }]
    })
  }
}
```

Even though the configuration must be YAML, we don't have to write it ourselves!
Instead, we can use the normal object notation of HCL and let `yamlencode` do the dirty work.
The configuration is then mounted into the Litestream sidecar.

At this point we have continuous replication of data set up.
But now if the App restarts, we're starting from an empty database again.
Litestream can help again, with its `restore` command:

```terraform
# In the original `kubernetes_deployment`...
resource "kubernetes_deployment" "app" {
  spec {
    template {
      spec {
        init_container {
          name = "litestream-restore-snapshot"
          image = ""
          args = [
              "restore",
              "-if-db-not-exists",
              "-if-replica-exists",
              var.sqlite_replicate.file_path
          ]

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_replicate.file_path)
          }
        }
      }
    }
  }
}
```

Now, when the `Deployment` starts/restarts, the init container will first restore the current database from the latest backup.
If there is no database file, one will be created.
If the backup can not be restored, the init container fails.
When an init container fails, no other containers of the deployment are started.
This makes the error state very obvious: The workload does not start at all.

Some details in the above configuration are omitted for brevity.
If you're interested, the full configuration is available [in my homeserver repo](https://github.com/LukasKnuth/homeserver/blob/main/deploy/modules/web_app/main.tf).

> ![note]
> For redundancy, I'm sending the backups both to my local NAS running MinIO and off-site to Wasabi S3 bucket.

This is all nice and good if it _works_, but how do I notice if it doesn't?

## Observability

fluentd, the go implementation because its smaller/faster/simpler

https://github.com/LukasKnuth/homeserver/lob/main/deploy/logs/main.tf
