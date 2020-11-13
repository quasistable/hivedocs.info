---
layout: default
title: Testnet
permalink: /testnet/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.content contains 'testnet'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
