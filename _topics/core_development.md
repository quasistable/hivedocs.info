---
layout: default
title: Core Development
permalink: /core-development/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'core' and post.categories contains 'development'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
