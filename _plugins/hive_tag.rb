# frozen_string_literal: true

require 'cgi'
require 'hive'
require 'open-uri'
require 'fileutils'
require 'json'
require 'time'

Net::OpenTimeout = Class.new(RuntimeError) unless Net.const_defined?(:OpenTimeout)
Net::ReadTimeout = Class.new(RuntimeError) unless Net.const_defined?(:ReadTimeout)

module Jekyll
  module Hive
    class HiveTag < Liquid::Tag
      def render(context)
        @encoding = context.registers[:site].config['encoding'] || 'utf-8'
        @settings = context.registers[:site].config['hive']

        if (tag_contents = determine_arguments(@markup.strip))
          hive_slug = tag_contents[0]
          attempts = 0
          content = nil
          rebuild = ENV.fetch('JEKYLL_HIVE_REBUILD', 'false') == 'true'

          loop do
            warn "Attempts for #{hive_slug}: #{attempts}" if attempts > 0

            if attempts > 4
              warn "Gave up on: #{hive_slug}"
              delete_content_cache(hive_slug)
              break
            end

            begin
              attempts += 1

              if rebuild && content_cache(hive_slug)
                if content_age(hive_slug) > 9000
                  warn "Checking for changes: #{hive_slug}"
                  if content_changed?(hive_slug)
                    warn "Refreshing: #{hive_slug}"
                    delete_content_cache(hive_slug)
                  end
                end

                content_touch(hive_slug)
              end

              content = content_cache(hive_slug) || hive_tag(hive_slug)
              break
            rescue => e
              warn "Retrying: #{hive_slug} (#{e})"
              @api = nil
              sleep 3
            end
          end

          content_cache(hive_slug, content)
        else
          raise ArgumentError, <<~ERROR
            Syntax error in tag 'hive' while parsing the following markup:
             #{@markup}
             Valid syntax:
              {% hive author/permlink %}

          ERROR
        end
      end

      private

      def cache_dir_path
        ENV.fetch('JEKYLL_HIVE_CACHE', '.jekyll-hive-cache')
      end

      def parse_key(hive_slug)
        hive_slug.gsub('/', '-')
      end

      def cached_file(hive_slug)
        key = parse_key(hive_slug)
        cache_dir_path + "/#{key}"
      end

      def content_cache(hive_slug, value = nil)
        key = parse_key(hive_slug)

        unless @content_cache
          @content_cache ||= {}

          FileUtils.mkdir_p(cache_dir_path)

          Dir.glob("#{cache_dir_path}/*") do |filename|
            next if File.directory? filename
            @content_cache[filename.split('/').last] = File.open(filename).read
          end
        end

        if value && value != ''
          @content_cache[key] ||= value
          File.open(cached_file(hive_slug), 'wb') { |cache_file| cache_file.write(value) }
        end

        if @content_cache[key] == ''
          delete_content_cache(hive_slug)
          nil
        else
          @content_cache[key]
        end
      end

      def content_age(hive_slug)
        Time.now - File.mtime(cached_file(hive_slug)) rescue 0
      end

      def content_touch(hive_slug)
        FileUtils.touch(cached_file(hive_slug))
      end

      def delete_content_cache(hive_slug)
        File.delete(cached_file(hive_slug)) rescue false
      end

      def determine_arguments(input)
        return unless input =~ /@?[^\/]+\/[^\/]+/i
        [input]
      end

      def api
        url = ENV.fetch('NODE_URL', 'https://api.hive.blog,https://api.openhive.network,https://api.c0ff33a.uk').split(',').sample
        @api ||= ::Hive::CondenserApi.new(url: url)
      end

      def parse_slug(hive_slug)
        hive_slug = hive_slug.split('@').last
        hive_slug = hive_slug.split('/')
        author = hive_slug[0]
        permlink = hive_slug[1..-1].join('/')
        permlink = permlink.split('?').first
        permlink = permlink.split('#').first
        [author, permlink]
      end

      def content_changed?(hive_slug)
        author, permlink = parse_slug(hive_slug)
        cached_created = File.mtime(cached_file(hive_slug)) rescue Time.now

        api.get_content(author, permlink) do |content|
          created = Time.parse(content.created + 'Z')
          cached_created > created
        end
      end

      def hive_tag(hive_slug)
        author, permlink = parse_slug(hive_slug)

        api.get_content(author, permlink) do |content|
          body = content.body
          metadata = JSON[content.json_metadata] rescue {}
          canonical_url = metadata.fetch('canonical_url', "https://hive.blog/@#{author}/#{permlink}")

          body = body.gsub(/https:\/\/steemitimages.com\/[0-9]+x0\/https:\/\//, 'https://')
          body = body.gsub(/https:\/\/images.hive.blog\/[0-9]+x0\/https:\/\//, 'https://')
          body = body.gsub(/https:\/\/images.esteem.app\/[0-9]+x0\/https:\/\//, 'https://')

          scrape = URI.open(canonical_url).read
          if scrape.include?('rel="canonical"')
            canonical_url = scrape.split('rel="canonical"')[1].split('"')[1]
          end

          <<~HTML
            <div class="hive-post-embed" data-hive-author="#{author}" data-hive-permlink="#{permlink}">
              <div id="content-#{author}-#{permlink}" class="hive-post-embed__content" data-hive-render-target="true">#{body}</div>
              <footer class="hive-post-embed__source">
                <span class="hive-post-embed__source-label">Source:</span>
                <a href="#{canonical_url}">#{content.title}</a>
                <span>by</span>
                <a href="https://hive.blog/@#{author}">@#{author}</a>
              </footer>
            </div>
          HTML
        end
      end
    end
  end
end

Liquid::Template.register_tag('hive', Jekyll::Hive::HiveTag)
