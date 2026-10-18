require 'json'
require 'yaml'
require 'time'
require 'net/http'
require 'uri'

module Hivedocs
  class Curation
    DEFAULT_CURSOR_PATH = '.curation-cursors.yml'.freeze
    DEFAULT_API_URL = 'https://api.openhive.network'.freeze
    DEFAULT_HAFBE_API_URL = 'https://api.hive.blog/hafbe-api'.freeze

    attr_reader :cursor_path, :api_url, :hafbe_api_url

    def initialize(cursor_path: DEFAULT_CURSOR_PATH, api_url: DEFAULT_API_URL, hafbe_api_url: DEFAULT_HAFBE_API_URL)
      @cursor_path = cursor_path
      @api_url = api_url
      @hafbe_api_url = hafbe_api_url
    end

    def load_cursors
      return {} unless File.exist?(cursor_path)

      YAML.load_file(cursor_path) || {}
    rescue StandardError => e
      raise "Failed to load #{cursor_path}: #{e.message}"
    end

    def save_cursors(data)
      File.write(cursor_path, data.to_yaml)
    end

    def hafbe_get(path, params = {})
      base = hafbe_api_url.sub(%r{/$}, '')
      uri = URI(base + path)
      uri.query = URI.encode_www_form(params) unless params.empty?
      response = Net::HTTP.get_response(uri)
      raise "HAFBE request failed for #{uri}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue StandardError => e
      raise "HAFBE request failed for #{path}: #{e.message}"
    end

    def fetch_author_post_permlinks(author, page:, page_size:)
      hafbe_get("/accounts/#{author}/comment-permlinks", {
        'comment-type' => 'post',
        'page' => page,
        'page-size' => page_size
      })
    end

    def fetch_content(author, permlink)
      rpc('condenser_api.get_content', [author, permlink])
    rescue RuntimeError => e
      raise unless e.message.include?('does not exist')

      nil
    end

    def each_author_post(author, page_size: 20, max_posts: nil)
      page = 1
      scanned = 0

      loop do
        batch = fetch_author_post_permlinks(author, page: page, page_size: page_size)
        permlinks = Array(batch['permlinks_result'])
        break if permlinks.empty?

        permlinks.each do |row|
          break if max_posts && scanned >= max_posts

          post = fetch_content(author, row['permlink'])
          next if post.nil?
          next unless post['author'] == author
          next unless post['parent_author'].to_s.empty?

          scanned += 1
          yield post
        end

        break if max_posts && scanned >= max_posts

        total_pages = batch['total_pages'].to_i
        break if total_pages <= 0 || page >= total_pages
        page += 1
      end
    end

    def canonical_url_for(post)
      metadata = JSON.parse(post['json_metadata'] || '{}') rescue {}
      metadata['canonical_url'] || "https://hive.blog/#{post['category']}/@#{post['author']}/#{post['permlink']}"
    end

    def post_time(post)
      created = post.is_a?(Hash) ? post['created'] : post.created
      Time.parse(created.to_s + (created.to_s.end_with?('Z') ? '' : 'Z')).utc
    rescue StandardError
      nil
    end

    def author_candidates(author, output_limit: 25, scan_limit: nil)
      output_limit = 25 if output_limit.to_i <= 0
      output_limit = output_limit.to_i
      scan_limit = scan_limit.to_i if scan_limit
      scan_limit = nil if scan_limit && scan_limit <= 0
      page_size = [[output_limit, 20].max, 100].min
      page_size = [[page_size, scan_limit].min, 1].max if scan_limit

      cursors = load_cursors
      cursor = cursors[author] || {}
      cursor_permlink = cursor['last_permlink']
      all_found = []
      hit_cursor = false
      scanned_posts = 0

      each_author_post(author, page_size: page_size, max_posts: scan_limit) do |post|
        scanned_posts += 1

        if cursor_permlink && post['permlink'] == cursor_permlink
          hit_cursor = true
          break
        end

        all_found << post
      end

      displayed = all_found.first(output_limit)

      {
        author: author,
        cursor_permlink: cursor_permlink,
        found: displayed,
        all_found_count: all_found.length,
        hit_cursor: hit_cursor,
        output_limit: output_limit,
        scan_limit: scan_limit,
        scanned_posts: scanned_posts,
        latest_candidate_permlink: all_found.first && all_found.first['permlink'],
        next_permlink_after_cursor: hit_cursor && all_found.any? ? all_found.last['permlink'] : nil
      }
    end

    def categories_for(author, source_category:, tags: [])
      cursor = load_cursors[author] || {}
      override_categories = Array(cursor['override_categories']).map(&:to_s).map(&:strip).reject(&:empty?)
      return override_categories unless override_categories.empty?

      candidates = Array(tags).map(&:to_s).map(&:strip).reject(&:empty?)
      candidates = [source_category.to_s.strip] + candidates if source_category.to_s.strip != ''
      candidates.uniq
    end

    def set_cursor(author, permlink)
      fetched = fetch_content(author, permlink)
      raise "No content found for @#{author}/#{permlink}" if fetched.nil?

      created = post_time(fetched)
      canonical_url = canonical_url_for(fetched)

      cursors = load_cursors
      existing = cursors[author] || {}
      cursors[author] = existing.merge(
        'last_permlink' => fetched['permlink'],
        'last_date' => created&.iso8601,
        'last_title' => fetched['title'],
        'canonical_url' => canonical_url,
        'updated_at' => Time.now.utc.iso8601
      )
      save_cursors(cursors)

      {
        author: author,
        permlink: fetched['permlink'],
        title: fetched['title'],
        created: created,
        canonical_url: canonical_url,
        raw: fetched
      }
    end

    def recommended_next_permlink(author, scan_limit: 250)
      result = author_candidates(author, output_limit: 1, scan_limit: scan_limit)
      result[:next_permlink_after_cursor]
    end

    # Communities and plain tags; bridge.get_ranked_posts treats both as a tag.
    SWEEP_TAGS = %w[hive-139531 hive-169321 hive-dev hivedevs hivedev dev].freeze
    SWEEP_BADGE = 'badge-424242'.freeze
    # Recurring posts never curated here: author => title pattern.
    SWEEP_SKIP = {
      'arcange' => /\AHive (Financial )?Statistics\b/,
      'hivegifbot' => //,
      'cubdaily' => //
    }.freeze
    # Categories never curated here: the Actifit community is fitness reports and app promotion.
    SWEEP_SKIP_CATEGORIES = %w[hive-193552 actifit].freeze

    def rpc(method, params)
      response = Net::HTTP.post(URI(api_url), { jsonrpc: '2.0', method: method, params: params, id: 1 }.to_json,
                                'Content-Type' => 'application/json')
      raise "RPC #{method} failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      error = body['error']
      if error
        detail = error['data'].is_a?(Hash) ? error['data'].dig('extension', 'assertion_expression') : error['data']
        raise "RPC #{method} failed: #{detail || error['message']}"
      end

      body['result']
    end

    # Newest-first community or tag feed; stops once posts are older than `from`.
    # ponytail: re-pages from today on every run, cache pages if month-by-month sweeps get slow.
    def each_tag_post(tag, from:)
      start = {}
      loop do
        batch = rpc('bridge.get_ranked_posts', { sort: 'created', tag: tag, observer: '', limit: 20 }.merge(start))
        batch.reject! { |p| p['author'] == start[:start_author] && p['permlink'] == start[:start_permlink] }
        return if batch.empty?

        batch.each do |post|
          next if post.dig('stats', 'is_pinned')
          return if post_time(post) < from

          yield post
        end
        start = { start_author: batch.last['author'], start_permlink: batch.last['permlink'] }
      end
    end

    def badge_members
      rpc('condenser_api.get_following', [SWEEP_BADGE, nil, 'blog', 1000]).map { |row| row['following'] }
    end

    def each_author_post_between(author, from:, to:)
      page = 1
      loop do
        batch = hafbe_get("/accounts/#{author}/comment-permlinks", {
          'comment-type' => 'post',
          'page' => page,
          'page-size' => 100,
          'from-block' => from.utc.strftime('%FT%T'),
          'to-block' => to.utc.strftime('%FT%T')
        })
        Array(batch['permlinks_result']).each do |row|
          begin
            post = fetch_content(author, row['permlink'])
          rescue RuntimeError => e
            warn "Skipping @#{author}/#{row['permlink']}: #{e.message}"
            next
          end
          yield post if post
        end
        return if page >= batch['total_pages'].to_i

        page += 1
      end
    end

    # Candidates in [from, to) from the dev communities and badge members, oldest first.
    def sweep(from:, to:, log: $stderr)
      found = {}
      add = lambda do |post, source|
        created = post_time(post)
        return unless created && created >= from && created < to
        return if SWEEP_SKIP[post['author']]&.match?(post['title'].to_s)
        return if SWEEP_SKIP_CATEGORIES.include?(post['category'])

        key = "@#{post['author']}/#{post['permlink']}"
        (found[key] ||= { post: post, created: created, sources: [] })[:sources] |= [source]
      end

      SWEEP_TAGS.each do |tag|
        log.puts "Scanning #{tag}..."
        each_tag_post(tag, from: from) { |post| add.(post, tag) }
      end
      badge_members.each do |author|
        log.puts "Scanning @#{author}..."
        each_author_post_between(author, from: from, to: to) { |post| add.(post, SWEEP_BADGE) }
      end

      found.values.sort_by { |f| f[:created] }
    end
  end
end
