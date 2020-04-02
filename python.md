---
layout: default
title: Python
permalink: /python/
---
{% assign filtered_posts = site.posts | where: "categories", "python" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
