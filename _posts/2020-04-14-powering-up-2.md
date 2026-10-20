---
layout: post
author: emrebeyler
title: "Hivesigner Python Client"
date: 2020-04-14 21:28:15 UTC
categories: howto hivesigner python wallet
canonical_url: https://hive.blog/hive-139531/@emrebeyler/powering-up-2
image: https://images.hive.blog/p/Y2iXpRRkNSnseh3NuL6KUBitJTXrc5K2vbTzBseGEENcE?format=match&mode=fit&width=640
---
<!-- Pinned: author blanked this post on chain 2026-10-18; body from jekyll-hive cache. -->
{% raw %}
<div class="hive-post-embed" data-hive-author="emrebeyler" data-hive-permlink="powering-up-2">
  <div id="content-emrebeyler-powering-up-2" class="hive-post-embed__content" data-hive-render-target="true"><center><img src="https://images.hive.blog/p/Y2iXpRRkNSnseh3NuL6KUBitJTXrc5K2vbTzBseGEENcE?format=match&mode=fit&width=640"></center>
***

hivesigner-python-client is a simple yet powerful library to interact with [HiveSigner](https://hivesigner.com). Hivesigner is a single sign-on solution for HIVE based applications and it implements `Oauth2` for the authorization logic.

With this client;

- Implementing Authorization/Authentication flow w/ OAuth
- Broadcasting supported operations to the HIVE blockchain with the user of your app

are possible through Hivesigner.


***
| Repository                                       | Documentation |
|--------------------------------------------------|---------------|
|[github.com/emre/hivesigner-python-client](https://github.com/emre/hivesigner-python-client )|   [hivesigner-python-client.readthedocs.io](https://hivesigner-python-client.readthedocs.io/en/latest/)            |
***

#### Installation
***
```
$ (sudo) pip install hivesigner
```

#### Migrating from steemconnect-python-client
***
If you use `steemconnect-python-client` and want to switch to HIVE version, the only change you need to do is updating imports.

Old way:

`from steemconnect.client import Client`

New way:

`from hivesigner.client import Client`.

Also, `Resteem` class is changed as `Reblog`.  Examples and more details can be found at the documentation website.
***
**Note**:  Hivesigner is being maintained by @good-karma since the switch. There is an ongoing proposal for it's maintenance for a while. If you didn't see it yet, [check it out](https://hivedao.com/proposal/88).</div>
  <footer class="hive-post-embed__source">
    <span class="hive-post-embed__source-label">Source:</span>
    <a href="https://hive.blog/hive-139531/@emrebeyler/powering-up-2">Hivesigner Python Client</a>
    by
    <a href="https://hive.blog/@emrebeyler">@emrebeyler</a>
  </footer>
</div>
{% endraw %}
