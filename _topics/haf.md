---
layout: default
title: HAF & HafSQL
permalink: /haf/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'haf' or post.categories contains 'sql' or post.categories contains 'database' or post.categories contains 'hafsql'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
