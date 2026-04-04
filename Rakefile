lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rake/testtask'
require 'json'
require 'yaml'
require 'hive'
require 'open-uri'
require 'time'
require 'uri'
require 'hivedocs/curation'
require 'hivedocs/description'
#require 'html-proofer'

namespace :assets do
  desc 'Update static assets'
  task :pull do
    # See: https://hive.blog/hive-139531/@keys-defender/phishing-on-hive-no-more-solution-for-all-frontends
    `curl -o assets/javascript/universal-bridge-against-phishing.js https://raw.githubusercontent.com/keys-defender/hive/master/scripts/universal-bridge-against-phishing.js`
    
    # Mainly fetched to monitor.  Usually we request a live version (no-cors).
    `curl -o spaminator-domains.json https://spaminator.me/api/p/domains.json`
  end
end

desc 'Grab a post.'
task :grab, :url do |t, args|
  url = args[:url] || abort('Url required.')
  api = Hive::Api.new(url: 'https://api.openhive.network')
  author, permlink = url.split('@').last.split('/')
  
  api.get_content(author, permlink) do |content|
    abort("No content found.") if content.id == 0
    
    canonical_url = "https://hive.blog/#{content.category}/@#{content.author}/#{content.permlink}"
    
    scrape = URI.open(canonical_url).read
    
    if scrape.include? 'rel="canonical"'
      canonical_url = scrape.split('rel="canonical"')[1].split('"')[1]
    end
    
    metadata = JSON[content.json_metadata] rescue {}
    tags = metadata.fetch('tags', [])
    description = metadata.fetch('description', nil)
    canonical_url = metadata.fetch('canonical_url', canonical_url)
    images = metadata.fetch('image', [])
    created_at = Time.parse(content.created + 'Z')
    curation = Hivedocs::Curation.new(
      cursor_path: '.curation-cursors.yml',
      api_url: ENV.fetch('HIVE_API_URL', Hivedocs::Curation::DEFAULT_API_URL),
      hafbe_api_url: ENV.fetch('HAFBE_API_URL', Hivedocs::Curation::DEFAULT_HAFBE_API_URL)
    )
    categories = curation.categories_for(content.author, source_category: content.category, tags: tags)
    description = Hivedocs::Description.derive(
      metadata_description: description,
      body: content.body,
      author: content.author,
      category: content.category,
      tags: tags
    )
    
    output = <<~DONE
      ---
      layout: post
      author: #{content.author}
      title: "#{content.title}"
      description: "#{description}"
      date: #{created_at.strftime('%Y-%m-%d %H:%M:%S')} UTC
      categories: #{categories.join(' ')}
      canonical_url: #{canonical_url}
      image: #{images[0] || 'https://hivedocs.info/assets/images/favicon.png'}
      ---
      {% hive #{author}/#{permlink} %}
    DONE
    
    new_post_path = "_posts/#{created_at.strftime('%Y-%m-%d')}-#{permlink}.md"
    
    File.open(new_post_path, 'w') do |f|
      f.write(output)
    end
    
    puts "Wrote to: #{new_post_path}"
  end
end

desc 'List of all posts.'
task :list do
  Dir.glob("_posts/*").sort_by{|f| f}.each do |filename|
    next if File.directory? filename
    
    post = File.open(filename).read
    
    puts post.split('canonical_url: ').last.split("\n").first
  end
end

namespace :curate do
  def curation
    @curation ||= Hivedocs::Curation.new(
      cursor_path: '.curation-cursors.yml',
      api_url: ENV.fetch('HIVE_API_URL', Hivedocs::Curation::DEFAULT_API_URL),
      hafbe_api_url: ENV.fetch('HAFBE_API_URL', Hivedocs::Curation::DEFAULT_HAFBE_API_URL)
    )
  end

  desc 'Show posts newer than the saved cursor for an author. Usage: rake curate:author[blocktrades]'
  task :author, [:author, :limit, :scan_limit] do |_t, args|
    author = args[:author].to_s.strip.sub(/^@/, '')
    abort('Usage: rake curate:author[author]') if author.empty?

    output_limit = (args[:limit] || ENV['LIMIT'] || 25).to_i
    scan_limit = (args[:scan_limit] || ENV['SCAN_LIMIT'] || 250).to_i
    result = curation.author_candidates(author, output_limit: output_limit, scan_limit: scan_limit)

    if result[:found].empty?
      if result[:cursor_permlink] && result[:hit_cursor]
        puts "No new posts for @#{author} since #{result[:cursor_permlink]}."
      elsif result[:cursor_permlink]
        puts "No posts found before reaching scan limit, or cursor #{result[:cursor_permlink]} was not encountered."
      else
        puts "No saved cursor for @#{author}."
      end
      next
    end

    result[:found].reverse_each do |post|
      created = curation.post_time(post)
      puts [
        (created ? created.strftime('%Y-%m-%d %H:%M:%S UTC') : post['created']),
        "@#{post['author']}/#{post['permlink']}",
        post['title'].to_s.strip.empty? ? '(untitled)' : post['title'],
        curation.canonical_url_for(post)
      ].join(" | ")
    end

    puts
    puts "#{result[:found].length} post(s) shown for @#{author}."
    puts(result[:cursor_permlink] ? "Cursor not advanced. Current cursor: #{result[:cursor_permlink]}" : 'No cursor saved yet.')
    puts "Latest candidate permlink: #{result[:latest_candidate_permlink]}"
    if result[:next_permlink_after_cursor]
      puts "Recommended next cursor permlink: #{result[:next_permlink_after_cursor]}"
    end
    puts 'Use rake curate:set_cursor[author,permlink] to advance after review.'
    puts "Scanned #{result[:scanned_posts]} post(s) while searching for cursor boundary."
    puts "Warning: cursor was not encountered within scan limit #{result[:scan_limit]}." if result[:cursor_permlink] && !result[:hit_cursor]
    puts "Warning: output limited to #{result[:output_limit]} post(s)." if result[:all_found_count] > result[:output_limit]
  end

  desc 'Grab the recommended next post for an author based on the saved cursor. Usage: rake curate:grab_next[blocktrades]'
  task :grab_next, [:author, :scan_limit] do |_t, args|
    author = args[:author].to_s.strip.sub(/^@/, '')
    abort('Usage: rake curate:grab_next[author]') if author.empty?

    scan_limit = (args[:scan_limit] || ENV['SCAN_LIMIT'] || 250).to_i
    permlink = curation.recommended_next_permlink(author, scan_limit: scan_limit)
    abort("No recommended next permlink found for @#{author}. Try a larger scan limit.") if permlink.to_s.empty?

    Rake::Task[:grab].invoke("https://hive.blog/@#{author}/#{permlink}")
  end

  desc 'Set the saved cursor for an author. Usage: rake curate:set_cursor[blocktrades,some-permlink]'
  task :set_cursor, [:author, :permlink] do |_t, args|
    author = args[:author].to_s.strip.sub(/^@/, '')
    permlink = args[:permlink].to_s.strip
    abort('Usage: rake curate:set_cursor[author,permlink]') if author.empty? || permlink.empty?

    result = curation.set_cursor(author, permlink)

    puts "Saved cursor for @#{author}: #{result[:permlink]}"
    puts "Title: #{result[:title]}"
    puts "Date: #{result[:created]&.strftime('%Y-%m-%d %H:%M:%S UTC') || result[:raw]['created']}"
    puts "URL: #{result[:canonical_url]}"
  end
end

desc 'Build site to docs for release.'
task :build do
  baseurl = ENV.fetch('BASEURL', '/')
  cmd = 'JEKYLL_ENV=production bundle exec jekyll build --destination docs'
  
  if !!baseurl && baseurl != '/'
    cmd += " --baseurl #{baseurl}"
  end
  
  sh cmd
end

desc 'Commit docs.'
task commit: [:build] do
  cmd = 'git add docs && git commit docs -m "jekyll base sources"'
    
  sh cmd
end

namespace :dump do
  desc 'Dump authors.'
  task :authors do
    puts `cat _site/authors.json | jq -r '. | values[]' | sort | uniq`
  end
end
