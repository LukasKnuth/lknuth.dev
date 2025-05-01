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
