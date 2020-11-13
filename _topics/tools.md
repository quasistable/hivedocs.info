---
layout: default
title: Tools
permalink: /tools/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.content contains 'tools'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
