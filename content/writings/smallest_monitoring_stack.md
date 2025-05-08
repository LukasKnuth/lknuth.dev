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

Again my goal was something simple that could run easily on my own infra.
There are many great hosted observability services out there, but that just adds extra complexity.
What if we just went much simpler?

I had a look around and decided to use Fluent Bit, the more lightweight and faster cousin of Fluentd.
Fluent Bit can easily be configured to stream any container logs that Kubernetes collects, enrich them with meta information and filter everything.

I'm primarily interested in knowing if anything is wrong with my Litestream replication.
For example, if my local NAS goes offline or if the internet connection to Wasabi drops.
Litestream will log these errors, and we can use that information to create alerts.

```
[INPUT]
  Name tail
  Alias kubernetes
  Path /var/log/containers/*.log
  Parser containerd
  Tag kubernetes.*

[FILTER]
  Name kubernetes
  Match kubernetes.*
  Merge_Log On
  # Many more specific settings...

[FILTER]
  Name grep
  Alias litestream-replicate
  Match kubernetes.*
  Logical_Op and
  Regex $kubernetes['container_name'] litestream-(sidecar|restore-snapshot)

[FILTER]
  Name rewrite_tag
  Match kubernetes.*
  Alias litestream-replication-problems
  Rule $level ^(WARN|ERROR)$ problem.$TAG true

[OUTPUT]
  Name stdout
  Alias stdout
  Match problem.*
  Format json_lines
```

The above is a _shortened_ version of my [full Fluent Bit config](https://github.com/LukasKnuth/homeserver/blob/143a99ea3a871e2baf6be2729e0dbcfe8842b3c5/deploy/logs/main.tf#L7).
You can read it top-to-bottom, although that's not necessarily how its executed.
Each group has a `Name` field which is the Fluent Bit plugin that is used.
Every `Filter` has a `Match` that specifies which logs the filter should be applied to.
The `Alias` they all set is just a more human-readable name for each step.

It starts with a `INPUT` that reads all log files that Kubernetes writes on disk on each node.
The path depends on your Kubernetes distribution, the above is for Talos Linux.
There is usually one log-file per container and we're just ingesting them all.

Next come the `FILTER` steps:

1. `kubernetes` adds additional meta information, such as container names to each log.
  - The `Merge_Log` checks if the log is JSON formatted and makes its structure available
  - Litestream can be [configured to log JSON](https://litestream.io/reference/config/#logging)
2. `grep` only retains logs made by containers named `litestream-sidecar` or `litestream-restore-snapshot`
  - These are the names used earlier when we configured the Litstream sidecar and init containers to the deployment.
3. `rewrite_tag` takes the filtered down logs and tags them with `problem.$TAG` if the log-level is either `WARN` or `ERROR`

After this, the `OUTPUT` writes all logs tagged `problem.*` to stdout as JSON lines.

### Alerting

This gives me a _single_ stream of all Errors/Warnings that Litestream encounters.
But I also want to be alerted if anything is going wrong so that I can investigate.
The simplest way to just get a notification is to send it via Slack:

```
[FILTER]
  Name throttle
  Match problem.*
  # Max burst 6msg/2h, 12h until recovered, 12msg/day
  Rate 1
  Interval 2h
  Window 6

[OUTPUT]
  Name slack
  Alias gotify
  Match problem.*
  Webhook https://my.slack.com/webhook/asdf1234
```

The `throttle` filter is there to reduce the number of events that could be sent.
If Litestream encounters a replication error every second, we don't need a Slack message with the same cadence.
The algorithm uses a [leaky bucket](https://docs.fluentbit.io/manual/pipeline/filters/throttle) which supports bursting.

Next, the throttled log stream is sent to the `slack` output.
My actual setup is a little more convoluted because I use my self-hosted Gotify instance with my [slack webhook plugin](https://github.com/LukasKnuth/gotify-slack-webhook) instead.
The full config is linked above, if you're curious.

Now when Litstream encounters an error while replicating _or_ restoring, I get notified about it.
And all that with a few simple extra containers.

## Chaos Engineering

> If you don't test your backups, you don't have backups.

The last piece of the puzzle is to regularly test if restoring from the replicated snapshots actually works.

The simple/brutal solution here is to just randomly have a cronjob restart deployments, so that the init job will restore the database.
I've done this manually in the past and it works.
However, should the backup not restore properly, there is no recourse - the last, unreplicated database is lost to the ephemeral storage.

My next idea was to just have a Cron job that simply runs the `restore` commands and verifies that it completed.
Then, we can use `PRAGMA quick_check` to validate that the resulting SQLite file is [not corrupted](https://www.sqlite.org/faq.html#q21).
Afterward, we can discard the file again, our replica is currently safe.


## Closing thoughts

There are certain shortcomings of my setup that you should consider:

- Litestream does not support multiple replicas. This means two things:
  - all workloads I host have `replicas = 1`
  - all workloads have `strategy = "Recreate"`
- This only works for SQLite databases, which reduces the number of workloads we can run
- Litestream development is not very active
  - that said, I have run this in "production" for about a year now without any problems
- Against Litestream recommendation, I don't use a PVC. If there is a catastrophic failure, like a power outage, some data might be lost
  - I live with this mainly because my applications don't generate data when I'm not actively using them
  - The increased simplicity with ephemeral storage is just too nice

All that said, SQLite is a rock solid piece of software and it performs incredibly well.
For a local homeserver that receives traffic from a handful of devices, its simplicity is hard to beat.
