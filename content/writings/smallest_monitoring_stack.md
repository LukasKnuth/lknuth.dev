---
title: "Persistent storage is for cowards"
date: 2025-05-30T16:20:00+02:00
---

About a year ago, I rebuild my home server.
It still runs on Kubernetes, but I moved away from traditional tooling associated with it.
The goal was simplicity; and I made some opinionated choices to achieve it.
For example, I deploy everything using Terraform with the Kubernetes provider - no more YAML!

For hardware, I just have a single Raspberry Pi 4.
There is no external storage attached to it, so everything is on an SD Card that could be corrupted at any point.
I would like very much for my application data to not be lost when that happens though.

<!--more-->

## Storage: deceptively complex

Kubernetes has support for persistent volumes out of the box.
They come in the form of `PersistentVolume` and `PersistentVolumeClaim`.

If a `Pod` has a `PersistentVolumeClaim`, the actual storage is provided on the nodes hard drive.
This means that if you have multiple nodes in your cluster, that specific `Pod` is now _colocated_ with the node.
Kubernetes does not have out-of-the-box options to move or replicate the `PersistentVolumeClaim` across its nodes.
It is possible to achieve this with a multitude of tools, none of which are _simple_.

The next problem is backups.
Ideally, we want to take backups of all types of data with the same process.
In practice, this is hardly possible.
Can you back up this storage while the application is _still running_?
Is there a way to guarantee that all writes are flushed to disk for a consistent backup?
Some applications offer backup commands that do just that.
Usually this means you'll be writing a custom `CronJob` per application.

Once you have that custom Job setup, the next question is: "how often do I run this?".
You can rephrase this to "how much data am I willing to lose?".
If you need to stop the application to ensure consistent backups, you need to balance availability with durability.

The last step is to regularly verify the backups you're taking.
"If you don't know that your backup works, you don't have a backup" as the common wisdom goes.
Ideally, this is also automated and happens regularly.

## Continuous Replication

Enter [Litestream](https://litestream.io/) for SQLite.
A simple tool that does one thing and does it really well: replicate one or multiple SQLite files from disk to an S3 storage.

The setup is very simple - no need to deploy any operator or CRDs.
It runs as a sidecar container to the actual application and just needs access to the SQLite database file on disk.
We can achieve both easily by sharing an `emptyDir` between the two containers:

```terraform
# NOTE: Valid but shortened.
resource "kubernetes_deployment" "some_app" {
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
          image = "litestream/litestream"
          args = ["replicate"]

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_file_path)
          }
        }

        container {
          name = "my-app"
          image = "lukasknuth/some-app"

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_file_path)
          }
        }
      }
    }
  }
}
```

Both the main application container and the Litestream sidecar access the same ephemeral storage volume.
Using ephemeral storage here also solves our data colocation problem: If the storage does not need to be retained across application starts, the `Pod` can be started on any node in the cluster.

> [!tip]
> The **ephemeral storage** means that the storage is permanently deleted after the `Pod` is stopped.
> That means every time the `Pod` starts, it starts with an empty storage folder. 

The `mount_path` above is configured as a parameter to the Terraform module.
I use the same parameter to create a `ConfigMap` that holds the configuration file for Litestream.

```terraform
resource "kubernetes_config_map_v1" "litestream_config" {
  metadata {
    name = "${var.app_name}-litestream-config"
  }

  data = {
    "litestream.yml" = yamlencode({
      dbs = [{
        path = var.sqlite_file_path,
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

Even though the configuration format is YAML, we don't have to write it ourselves!
Instead, we can use the normal object notation of HCL and let `yamlencode` do the dirty work.
The configuration is then mounted into the Litestream sidecar.

At this point we have continuous replication of data set up.
But now if the App restarts, we're starting with an empty database.
Litestream can help again, with its `restore` command:

```terraform
# In the original `kubernetes_deployment` from above...
resource "kubernetes_deployment" "some_app" {
  spec {
    template {
      spec {
        init_container {
          name = "litestream-restore-snapshot"
          image = "litestream/litestream"
          args = [
              "restore",
              "-if-db-not-exists",
              "-if-replica-exists",
              var.sqlite_file_path
          ]

          volume_mount {
            name = "application-state"
            mount_path = dirname(var.sqlite_file_path)
          }
        }
      }
    }
  }
}
```

Now, when the `Pod` starts/restarts, the init container will first restore the current database from the latest replica.
If there is no replica, an empty database is created (relevant on first launch).
If the replica can not be restored, the init container fails and the application does not start.
This makes the error state very obvious: The application isn't available and can't generate new data that might be lost as well.

Some details in the above configuration are omitted for brevity.
If you're interested, the full configuration is available [in my homeserver repo](https://github.com/LukasKnuth/homeserver/blob/main/deploy/modules/web_app/main.tf).

> [!note]
> For redundancy, you can send the replicas to multiple S3 targets.
> I currently just use my local NAS running MinIO.
> The storage on the NAS is then further backed up off-site to Wasabi.

This is all nice and good if it _works_, but how do I notice if it doesn't?

## Observability

Again, I'm going for simplicity.
There are many great hosted observability services out there, but that just adds extra complexity.
What if we just went much simpler?

I had a look around and decided to use Fluent Bit, the more lightweight cousin of Fluentd.
Fluent Bit can easily be configured to stream any container logs that Kubernetes collects, enrich them with metadata and filter everything.

I'm primarily interested in knowing if anything is wrong with my Litestream replication.
For example, if my NAS goes offline or if the local network connection drops.
Litestream will log these errors, and we can turn them into alerts.

```
[INPUT]
  Name tail
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
  Match kubernetes.*
  Logical_Op and
  Regex $kubernetes['container_name'] litestream-(sidecar|restore-snapshot)

[FILTER]
  Name rewrite_tag
  Match kubernetes.*
  Rule $level ^(WARN|ERROR)$ problem.$TAG true

[OUTPUT]
  Name stdout
  Match problem.*
  Format json_lines
```

The above is a _shortened_ version of my [full Fluent Bit config](https://github.com/LukasKnuth/homeserver/blob/143a99ea3a871e2baf6be2729e0dbcfe8842b3c5/deploy/logs/main.tf#L7).
You can read it top-to-bottom, although that's not necessarily how its executed.
Each group has a `Name` field which is the Fluent Bit plugin that is used.
Every `Filter` has a `Match` that specifies which logs (identified by `Tag`s) the filter should be applied to.

It starts with a `INPUT` that reads all log files that Kubernetes writes to disk on each node.
The path depends on your Kubernetes distribution, the above is for Talos Linux.
There is usually one log-file per container, and we're just ingesting them all.

Next come the `FILTER` steps:

1. `kubernetes` adds additional metadata, such as the container name, to each log.
    - The `Merge_Log` checks if the log is JSON formatted and makes its structure available
    - Litestream can be [configured to log JSON](https://litestream.io/reference/config/#logging)
2. `grep` only retains logs made by containers named `litestream-sidecar` or `litestream-restore-snapshot`
    - These are the names used earlier when we configured the Litstream sidecar and init containers to the deployment.
3. `rewrite_tag` takes the filtered down logs and tags them with `problem.$TAG` if the log-level is either `WARN` or `ERROR`
    - The `$level` is available because it was parsed out of the JSON log earlier.

After this, the `OUTPUT` writes all logs tagged `problem.*` to stdout as JSON lines.
This gives me a _single_ stream of all Errors/Warnings that Litestream encounters.
Easy to verify if we catch everything, halfway there.

### Alerting

I want to be alerted if anything is going wrong so that I can investigate in a timely maner.
After all, data could be lost if the problem isn't resolved.
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
  Match problem.*
  Webhook https://my.slack.com/webhook/asdf1234
```

The `throttle` filter puts an upper bound on the number of notifications that are sent.
If Litestream encounters a replication error and retires every second, we don't need Slack messages with the same cadence.
The algorithm uses a [leaky bucket](https://docs.fluentbit.io/manual/pipeline/filters/throttle) which supports bursting.

Next, the throttled log stream is sent to the `slack` output.
My actual setup is a little more convoluted because I use my self-hosted Gotify instance with my [slack webhook plugin](https://github.com/LukasKnuth/gotify-slack-webhook) instead.
The full config is linked above, if you're curious.

Now when Litstream encounters an error while replicating _or_ restoring, I get notified about it.

## Trust but verify

> If you don't test your backups, you don't have backups.

A simple/brutal solution would be to just randomly have a cronjob restart deployments, so that the init container will restore the database.
I've done this manually in the past and it works.
However, should the backup not restore properly, there is no recourse - the latest, unreplicated changes are lost to the ephemeral storage.

Instead, let's have the Cronjob run the `litestream restore` command and verify that it completed successfully.
Then, we can use `PRAGMA integrity_check` to validate that the resulting SQLite file is [not corrupted](https://www.sqlite.org/faq.html#q21).

```fish
# - `APP_DB_PATH` set to the full path of the apps database
# - `HEALTHCHECKS_IO_URL` the `hc-ping.com` URL with a UUID
set -l local_db "/app/db.sqlite"

# First, restore database from newest replica generation
# If successfull, verify the integrity of the restored database
set -l log (
  litestream restore -o $local_db $APP_DB_PATH 2>&1;
  and sqlite3 $local_db "PRAGMA integrity_check" 2>&1
)

# Report status and post captured log to healthcheck.io
set -l url "$HEALTHCHECKS_IO_URL/$status"
curl -m 20 --retry 5 --data-raw "$(string split0 $log)" $url
```

The above [Fish script](https://fishshell.com/docs/current/language.html) does just that.
It uses [healthchecks.io](https://healthchecks.io/) which knows the cron schedule and will email me if the job doesn't ping it.
It also captures `stdout` and `stderr` from both commands and sends the exit code in the ping.
If something is amiss, I have all the information in one place.

I have currently scheduled these jobs to run once a week in the early hours of Saturday.
They're all spread out so that only one runs at a time.

## Closing thoughts

I have run this setup in production for a year now (minus the verification - I like to live dangerously).
In this time I had one failure that I was quickly alerted to and able to fix.

SQLite is a battle tested piece of software and performs incredibly well.
Litestream replication is rock solid and I trust the monitoring.
But the simplicity comes with tradeoffs that you should consider before adopting.

This specific setup only works for SQLite.
That means I can only run apps that use/allow SQLite as their storage backend.
This sometimes means I can't run an application I'd like, but I've always found alternatives.

Litestream does not support multiple replicas - although [this is changing](https://fly.io/blog/litestream-revamped/).
Currently, all `Deployments` have `replicas = 1` and `strategy = "Recreate"` to ensure there are never two instances of the same application running.
The result is a short downtime on restart and no option to scale horizontally - both of which I can live with.

Against Litestream recommendation, I don't use a PVC.
If there is a catastrophic failure, like a power outage, some data might not have been replicated yet and is lost.
I accept this mainly because applications I host don't generate data when I'm not interacting with them.

If you can live with these caveats, you get a beautifully simple setup.
