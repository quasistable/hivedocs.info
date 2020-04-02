---
layout: default
---
{% assign howto_posts = site.posts | where: "categories", "howto" %}

{%- if howto_posts.size > 0 -%}
  <h2 class="post-list-heading">{{ page.list_title | default: "How To" }}</h2>
  <ul class="post-list">
    {%- for post in howto_posts -%}
      {%- include post_li.html post=post -%}
    {%- endfor -%}
  </ul>
{%- endif -%}
