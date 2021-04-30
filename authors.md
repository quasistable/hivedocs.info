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

<hr />

<ul>
  <li>
    Find new posts by these author on:
    <ul>
      <li /><a href="https://hyperion.zone/posts?utf8=√&author%5B%5D={{ authors | join: '&author%5B%5D=' }}">hyperion.zone</a>
      <li /><a href="https://peakd.com/b/badge-424377">B/Hive Chain Documentation Authors</a>
    </ul>
  </li>
  <li />Active developers on the Hive Blockchain: <a href="https://peakd.com/b/badge-424242">B/Hive Devs</a>
  <li />Community: <a href="https://peakd.com/c/hive-139531/created">HiveDevs</a>
  <li />Community: <a href="https://peakd.com/c/hive-169321/created">Programming/Dev Community</a>
</ul>
