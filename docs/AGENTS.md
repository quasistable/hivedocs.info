# Agent notes for hivedocs.info

Build, publish and curation policy live in `README.md`. This file records
operational lessons for agents working the curation tooling.

## Hive API behavior

- hive.blog returns 403 to scripted requests. Never depend on scraping a
  hive.blog page; `rake grab` and jekyll-hive 2.0 fall back to the post
  metadata or the plain hive.blog URL for the canonical link.
- `condenser_api.get_content` no longer returns a post `id`, and a missing
  post comes back as an RPC error ("does not exist"). Use
  `Hivedocs::Curation#fetch_content`, which handles both. hive-ruby's client
  no longer exposes `get_content` on api.openhive.network; call JSON-RPC
  directly.
- api.hive.blog rate-limits parallel requests. 8 threads returned mostly
  empty results; 3 threads spread across api.hive.blog and
  api.openhive.network, with retries and backoff, fetched 1,600 posts with
  no misses.
- HAFBE `comment-permlinks` date filters can leak posts from outside the
  window. Filter by `created` again after fetching.
- Authors sometimes blank posts by editing title and body to `.`. Treat that
  as a removal and do not import the post. If the post is already curated,
  pin it: replace the `{% hive %}` tag with the cached embed from
  `.jekyll-hive-cache/` wrapped in `{% raw %}`.
- HAFBE `comment-permlinks` windows match the latest edit, not creation. A
  mass edit (@emrebeyler blanked ~880 posts on 2026-10-18) floods the window,
  and the sweep fetches every one before the `created` filter drops it. A slow
  badge-member scan usually means this, not a hang.

## Sweep and grab

- `rake curate:sweep[from,to]` takes 12–25 minutes for a year, mostly paging
  tag feeds back from today. Run it in the background with a long timeout
  (2 hours); a 10-minute limit killed one run.
- Sweep a year or more per run instead of month by month, so the tag feeds
  are paged once.
- `rake grab` writes the post's raw Hive tags as categories. Replace them by
  hand with `section topic...` (for example `news core development`), matching
  earlier posts.
- After grabbing, build and check that every new page has a body. A blank
  body means jekyll-hive failed to fetch the post; check the build log for
  `Gave up on:`.

## Triage with subagents

- Give each subagent one quarter (300–500 entries) of excerpts plus the
  owner's rulings and examples of confirmed includes and excludes.
- Pin the output format: includes one per line with the URL; excludes one
  author per line as `- @author (count): reason`. Free-form exclude groupings
  made count checks fail.
- Verify each batch: include + exclude counts equal the input count, and
  every included URL appears in the input.
- Reject cross-posts (permlinks ending `-hive-169321`, bodies starting "This
  is a cross post of"); triage picked these over the originals once.
