---
layout: default
title: Hardfork
permalink: /hardfork/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.content contains 'hardfork'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
