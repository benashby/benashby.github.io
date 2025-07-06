---
layout: page
title: Resources
permalink: /resources/
---

# Resources

This section contains guides, references, and other long-lived content that goes beyond regular blog posts.

## Available Resources

<div class="resources-list">
{% for resource in site.resources %}
  <article class="resource-item">
    <h3><a href="{{ resource.url | prepend: site.baseurl }}">{{ resource.title }}</a></h3>
    {% if resource.description %}
      <p>{{ resource.description }}</p>
    {% endif %}
  </article>
{% endfor %}
</div>

{% if site.resources.size == 0 %}
  <p><em>No resources available yet. Check back soon!</em></p>
{% endif %}