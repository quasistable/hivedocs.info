---
layout: post
author: emrebeyler
title: "hived-rpc-scanner update: v0.1.1"
description: "CLI tool to check the status of Hive RPC nodes by testing certain endpoints"
date: 2022-10-13 23:28:09 UTC
categories: tools python nodes
canonical_url: https://hive.blog/hive-129924/@emrebeyler/hived-rpc-scanner-update-v0-1-0
image: https://images.hive.blog/DQmaL2iLfjwfBB2vXDDVRoopYimJ78WWKXUNrhHGMr5nAfH/Screenshot%202022-10-14%20at%2001.19.27.png
---
<!-- Pinned: author blanked this post on chain 2026-10-18; body from jekyll-hive cache. -->
{% raw %}
<div class="hive-post-embed" data-hive-author="emrebeyler" data-hive-permlink="hived-rpc-scanner-update-v0-1-0">
  <div id="content-emrebeyler-hived-rpc-scanner-update-v0-1-0" class="hive-post-embed__content" data-hive-render-target="true">`hived_rpc_scanner` is a CLI tool to check the status of Hive RPC nodes by testing certain endpoints.


![Screenshot 2022-10-14 at 01.19.27.png](https://images.hive.blog/DQmaL2iLfjwfBB2vXDDVRoopYimJ78WWKXUNrhHGMr5nAfH/Screenshot%202022-10-14%20at%2001.19.27.png)

***
# Installation

Requires Python3.6+.

```
$ (sudo) pip install hived_rpc_scanner
```
***
alternatively, with Virtualenv:

```
cd /tmp
python3.6 -m venv hived-rpc-scanner-env
source hived-rpc-scanner-env/bin/activate
pip install hived-rpc-scanner
hived_rpc_scanner
```
***
if you already have an old version, try upgrading with `pip install hived_rpc_scanner --upgrade`.

# Usage

```
$ hived_rpc_scanner --nodes <node_url_1> <node_url_2> <...>
```

# Changelog

- Removed deprecated tag api samples.
- Added samples for `json_rpc`, `market_history_api`, `rc_api`, `reputation_api`. With these changes, we have at least one sample for each plugin.
- CLI command (`hived_rpcs_scanner`) exits with a non-zero status code if one of the endpoints fail. Useful for CI/CD pipelines and smoke tests.</div>
  <footer class="hive-post-embed__source">
    <span class="hive-post-embed__source-label">Source:</span>
    <a href="https://hive.blog/hive-129924/@emrebeyler/hived-rpc-scanner-update-v0-1-0">hived-rpc-scanner update: v0.1.1</a>
    by
    <a href="https://hive.blog/@emrebeyler">@emrebeyler</a>
  </footer>
</div>
{% endraw %}
