---
layout: default
title: Archive
permalink: /archive/
---

<table class="table" style="margin-bottom: 10px; width: 100%; text-align: left; color: #4a535c; border-collapse: collapse; border: 1px solid #7e8b98;">
{%- for post in site.posts -%}
  {%- assign date_format = site.minima.date_format | default: "%b %-d, %Y" -%}
  
  <tr>
    <td style="padding: 4px; font-size: 11px;">{{ post.date | date: date_format }}</td>
    <td style="padding: 4px;">
      <a class="post-link" href="{{ post.url | relative_url }}" style="font-size: 11px;">
        {{ post.title | escape }}
      </a>
    </td>
  </tr>
{%- endfor -%}
</table>
