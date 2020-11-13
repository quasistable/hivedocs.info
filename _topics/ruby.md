---
layout: default
title: Ruby
permalink: /ruby/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'ruby'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
