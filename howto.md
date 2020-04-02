---
layout: default
title: How To
permalink: /howto/
---
{% assign filtered_posts = site.posts | where: "categories", "howto" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
