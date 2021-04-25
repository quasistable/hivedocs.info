---
layout: default
title: Authors
permalink: /authors/
---
{% assign authors = '' | split: ',' %}
{% assign sorted_posts = site.posts | sort: 'author' %}
{%- for post in sorted_posts -%}
  {% unless authors contains post.author %}
    {% assign authors = authors | push: post.author %}
  {% endunless %}
{%- endfor -%}

<h3>Authors</h3>
<ul>
  {%- for author in authors -%}
    <li class="list-style-avatar" style="background-image: url(https://images.hive.blog/u/{{ author }}/avatar/small)">
      <a name="author-{{ author }}"></a>
      <a href="https://hive.blog/@{{ author }}">{{ author }}</a>
      <ul>
        {%- for post in site.posts -%}
          {% if author == post.author %}
            <li><small><a href="{{ post.url }}">{{ post.title }}</a></small></li>
          {% endif %}
        {%- endfor -%}
      </ul>
    </li>
  {%- endfor -%}
</ul>
