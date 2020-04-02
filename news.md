---
layout: default
title: News
permalink: /news/
---
{% assign filtered_posts = site.posts | where: "categories", "news" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
