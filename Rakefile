lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rake/testtask'
require 'json'
require 'yaml'
require 'hive'
require 'open-uri'
#require 'html-proofer'

namespace :assets do
  desc 'Update static assets'
  task :pull do
    # See: https://hive.blog/hive-139531/@keys-defender/phishing-on-hive-no-more-solution-for-all-frontends
    `curl -o assets/javascript/universal-bridge-against-phishing.js https://raw.githubusercontent.com/keys-defender/hive/master/scripts/universal-bridge-against-phishing.js`
  end
end

desc 'Grab a post.'
task :grab, :url do |t, args|
  url = args[:url] || abort('Url required.')
  api = Hive::Api.new(url: 'https://anyx.io')
  author, permlink = url.split('@').last.split('/')
  
  api.get_content(author, permlink) do |content|
    abort("No content found.") if content.id == 0
    
    canonical_url = "https://hive.blog/#{content.category}/@#{content.author}/#{content.permlink}"
    
    scrape = open(canonical_url).read
    
    if scrape.include? 'rel="canonical"'
      canonical_url = scrape.split('rel="canonical"')[1].split('"')[1]
    end
    
    metadata = JSON[content.json_metadata] rescue {}
    tags = metadata.fetch('tags', [])
    description = metadata.fetch('description', nil)
    canonical_url = metadata.fetch('canonical_url', canonical_url)
    images = metadata.fetch('image', [])
    created_at = Time.parse(content.created + 'Z')
    
    output = <<~DONE
      ---
      layout: post
      author: #{content.author}
      title: "#{content.title}"
      description: "#{description}"
      date: #{created_at.strftime('%Y-%m-%d %H:%M:%S')} UTC
      categories: #{tags.join(' ')}
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
