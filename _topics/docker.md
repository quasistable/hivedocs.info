---
layout: default
title: Docker
permalink: /docker/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.content contains 'docker'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
