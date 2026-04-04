# hivedocs.info

hivedocs.info is my Hive docs-and-curation project.

I originally picked up this domain because I thought I was going to build a Hive developer portal here.

That plan changed when Blocktrades stepped up and took over the repositories that had come from Steemit, Inc., including the existing developer portal work. Once that happened, building a parallel portal from scratch felt a lot less necessary.

Since I had already registered `hivedocs.info`, I retooled the site into something narrower and more personal: a curated collection of posts, references, and technical breadcrumbs related to Hive development.

So this project shifted from "build the portal" to "keep track of the technical side of Hive well enough that useful material does not disappear into the feed."

## What I use it for

I use this site to follow:
- core Hive development
- major Hive tools and infrastructure
- reference implementations and technical resources worth preserving

This is not meant to catalog every Hive post under the sun. It is meant to track the things that matter if you are trying to understand, maintain, build on, or keep up with the ecosystem as a developer.

That includes things like:
- protocol and consensus changes
- node, API, and infrastructure work
- wallets, libraries, SDKs, and tooling
- developer writeups and implementation notes
- reference material that helps future builders find the shape of the system

A lot of this is curation work, and curation is messy. People post in different places, use inconsistent tags, disappear for stretches, or move on to other things. The point of the site is to impose a little order on that mess.

The repo is privately hosted under the **Quasistable** organization.

This project has also been pretty quiet for a while. My own activity dropped off around **November 2022**, but the reason to keep the site around is still the same.

## Repo shape

This is a Jekyll site.

Important paths:
- `_posts/` — source posts and imported content stubs
- `_topics/` — topic pages and category-driven views
- `_layouts/`, `_includes/`, `_sass/` — site presentation and shared templates
- `docs/` — committed built output used for publishing

## Publishing flow

Content is curated into the repo and rendered by Jekyll.

Current workflow notes:
- `rake build` builds the site into `docs/`
- `rake commit` explicitly stages and commits `docs/`, so committed built output is intentional
- `bundle exec jekyll build` writes disposable local output into `_site/`
- topic and category views are driven from site content rather than being treated as a separate application layer
- `_topics/` is a manual Jekyll collection used for topic landing pages

## Project structure and build notes

A few repo details are easy to forget, so here they are explicitly:

- `docs/` is the committed publish artifact.
- `_site/` is local/generated output and should be treated as disposable.
- `_posts/` is the main content intake path.
- `_topics/` contains hand-authored topic landing pages, not generated output.
- `rake grab[url]` fetches a live Hive post and creates a `_posts/YYYY-MM-DD-permlink.md` stub using `{% hive author/permlink %}`.

### Locale

Local Jekyll builds should run in a UTF-8 locale. A shell that falls back to `US-ASCII` can trigger Markdown conversion failures during build.

Expected environment:

```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Sass / theme status

This repo now carries local Minima Sass overrides and vendored Minima partials under `_sass/`.

Current state:
- visible `lighten(...)` / `darken(...)` deprecation warnings were reduced by replacing them with `color.adjust(...)`
- the remaining Sass warning noise comes from the older `@import`-based Minima structure
- that warning is non-blocking for now, but the theme has not been fully migrated to modern Sass module syntax

## Curation notes

The hard part is not rendering the site. The hard part is deciding what deserves to be tracked.

New material may come from developers, communities, badges, and reference repos. Curation should favor signal over volume.

### Places I look for new posts

Not all developers use the same tags or communities, but many of them are tracked by the HiveDevs badge or use the HiveDevs community.

- https://peakd.com/c/hive-139531/created — Community: HiveDevs
- https://peakd.com/c/hive-169321/created — Community: Programming/Dev Community
- https://peakd.com/b/badge-424242 — Badge: HiveDevs (badge maintained by @asgarth)
  - `curl -s --data '{"jsonrpc":"2.0", "method":"condenser_api.get_following", "params":{"account":"badge-424242","start":null,"type":"blog","limit":1000}, "id":1}' https://api.hive.blog | jq -r .result[].following`

## Development

Typical local flow:

```bash
bundle install
rake build
bundle exec jekyll serve
```

If this is a fresh clone, expect cache warmup behavior from Hive-related content fetches on the first local build/serve pass.
