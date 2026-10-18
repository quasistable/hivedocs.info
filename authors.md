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

<div class="authors-intro">
  <p>This page groups the authors currently represented on hivedocs.info and provides quick links into their archived posts.</p>
</div>

<div class="author-directory">
  {%- for author in authors -%}
    <section class="author-card" id="author-{{ author }}">
      <div class="author-card__header">
        <img class="author-card__avatar lazyload" data-src="https://images.hive.blog/u/{{ author }}/avatar" alt="Avatar for @{{ author }}" width="72" height="72" />
        <div class="author-card__meta">
          <h3 class="author-card__name"><a href="https://hive.blog/@{{ author }}">@{{ author }}</a></h3>
          {%- assign author_posts = site.posts | where: 'author', author -%}
          <p class="author-card__count">{{ author_posts | size }} archived post{% if author_posts.size != 1 %}s{% endif %}</p>
        </div>
      </div>

      <ul class="author-card__posts">
        {%- for post in author_posts -%}
          <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
        {%- endfor -%}
      </ul>
    </section>
  {%- endfor -%}
</div>

<section class="authors-resources">
  <h3>Discovery and follow-up</h3>
  <ul>
    <li>New posts by these authors: <a href="https://www.hyperion.zone/posts?utf8=√&author%5B%5D={{ authors | join: '&author%5B%5D=' }}">hyperion.zone</a></li>
    <li><a href="https://peakd.com/b/badge-424377">B/Hive Chain Documentation Authors</a></li>
    <li>Active developers on the Hive blockchain: <a href="https://peakd.com/b/badge-424242">B/Hive Devs</a></li>
    <li>Community: <a href="https://peakd.com/c/hive-139531/created">HiveDevs</a></li>
    <li>Community: <a href="https://peakd.com/c/hive-169321/created">Programming/Dev Community</a></li>
  </ul>
</section>
