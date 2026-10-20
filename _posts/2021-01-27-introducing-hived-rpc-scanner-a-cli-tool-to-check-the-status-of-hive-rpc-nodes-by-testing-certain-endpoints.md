---
layout: post
author: emrebeyler
title: "hived-rpc-scanner: A tool to check the status of Hive RPC nodes by testing certain endpoints."
description: "`hived_rpc_scanner` is a CLI tool to check the status of Hive RPC nodes by testing certain endpoints."
date: 2021-01-27 21:20:09 UTC
categories: news devops api
canonical_url: https://peakd.com/hive-139531/@emrebeyler/introducing-hived-rpc-scanner-a-cli-tool-to-check-the-status-of-hive-rpc-nodes-by-testing-certain-endpoints
image: https://i.imgur.com/0NWDpWz.png
---
<!-- Pinned: author blanked this post on chain 2026-10-18; body from jekyll-hive cache. -->
{% raw %}
<div class="hive-post-embed" data-hive-author="emrebeyler" data-hive-permlink="introducing-hived-rpc-scanner-a-cli-tool-to-check-the-status-of-hive-rpc-nodes-by-testing-certain-endpoints">
  <div id="content-emrebeyler-introducing-hived-rpc-scanner-a-cli-tool-to-check-the-status-of-hive-rpc-nodes-by-testing-certain-endpoints" class="hive-post-embed__content" data-hive-render-target="true">Repository:
https://github.com/emre/hived-rpc-scanner

`hived_rpc_scanner` is a CLI tool to check the status of Hive RPC nodes by testing certain endpoints.

<center><img src="https://i.imgur.com/0NWDpWz.png"></center>

# Installation

Requires Python3.6+.

```
$ (sudo) pip install hived_rpc_scanner
```

# Usage

```
$ hived_rpc_scanner --nodes <node_url_1> <node_url_2> <...>
```

# Notes

- The listed endpoints are a subset of available endpoints. There is still a possibility that some of the endpoints in the tested API host may not work, while this tool shows everything in green.

- There are certain sanity checks applied for each endpoint. E.g: Structure of the response, element counts, element types.  You can see the whole validator set [here](https://github.com/emre/hived-rpc-scanner/blob/main/hived_rpc_scanner/validators.py).

- If you're an app developer and some of your favorite endpoints are not listed here, let me know so I can add them to the test list.

Enjoy.</div>
  <footer class="hive-post-embed__source">
    <span class="hive-post-embed__source-label">Source:</span>
    <a href="https://peakd.com/hive-139531/@emrebeyler/introducing-hived-rpc-scanner-a-cli-tool-to-check-the-status-of-hive-rpc-nodes-by-testing-certain-endpoints">hived-rpc-scanner: A tool to check the status of Hive RPC nodes by testing certain endpoints.</a>
    by
    <a href="https://hive.blog/@emrebeyler">@emrebeyler</a>
  </footer>
</div>
{% endraw %}
