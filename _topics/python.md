---
layout: default
title: Python
permalink: /python/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'python'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
