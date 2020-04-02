---
layout: default
---
{% assign news_posts = site.posts | where: "categories", "news" %}

{%- if news_posts.size > 0 -%}
  <h2 class="post-list-heading">{{ page.list_title | default: "News" }}</h2>
  <ul class="post-list">
    {%- for post in news_posts -%}
      {%- include post_li.html post=post -%}
    {%- endfor -%}
  </ul>
{%- endif -%}
