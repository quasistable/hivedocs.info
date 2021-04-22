---
layout: default
title: Witness
permalink: /witness/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'witness'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
