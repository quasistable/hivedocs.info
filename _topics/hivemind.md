---
layout: default
title: Hivemind
permalink: /hivemind/
---
{% assign filtered_posts = site.posts | where_exp: "post", "post.categories contains 'hivemind' or post.content contains 'hivemind'" %}

{%- include filtered_posts.html filtered_posts=filtered_posts -%}
