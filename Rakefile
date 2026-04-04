lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'rake/testtask'
require 'json'
require 'yaml'
require 'hive'
require 'open-uri'
#require 'html-proofer'

begin
  require 'tiny_tds'
rescue LoadError
end

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

desc 'List of all posts.'
task :list do
  Dir.glob("_posts/*").sort_by{|f| f}.each do |filename|
    next if File.directory? filename
    
    post = File.open(filename).read
    
    puts post.split('canonical_url: ').last.split("\n").first
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

namespace :hivesql do
  def load_env_file(path = '.env')
    return {} unless File.exist?(path)

    File.readlines(path).each_with_object({}) do |line, memo|
      line = line.strip
      next if line.empty? || line.start_with?('#') || !line.include?('=')

      key, value = line.split('=', 2)
      memo[key] = value
    end
  end

  def hivesql_config
    env_file = load_env_file

    {
      host: ENV['HIVE_SQL_HOST'] || env_file['HIVE_SQL_HOST'],
      port: ENV['HIVE_SQL_PORT'] || env_file['HIVE_SQL_PORT'],
      username: ENV['HIVE_SQL_ACCOUNT'] || env_file['HIVE_SQL_ACCOUNT'],
      password: ENV['HIVE_SQL_PASSWORD'] || env_file['HIVE_SQL_PASSWORD'],
      database: ENV['HIVE_SQL_DATABASE'] || env_file['HIVE_SQL_DATABASE']
    }
  end

  def hivesql_redacted_summary(config)
    {
      host: config[:host],
      port: config[:port],
      username: config[:username],
      database: config[:database]
    }.compact
  end

  def hivesql_client
    abort('Missing gem dependency: tiny_tds. Run bundle install.') unless defined?(TinyTds::Client)

    config = hivesql_config
    missing = [:host, :username, :password].select { |k| config[k].nil? || config[k].empty? }
    abort("Missing HiveSQL config: #{missing.join(', ')}") unless missing.empty?

    client_options = {
      username: config[:username],
      password: config[:password],
      host: config[:host],
      timeout: 15
    }
    client_options[:port] = Integer(config[:port]) unless config[:port].to_s.empty?
    client_options[:database] = config[:database] unless config[:database].to_s.empty?

    TinyTds::Client.new(**client_options)
  rescue TinyTds::Error => e
    warn "HiveSQL connection failed with config: #{JSON.generate(hivesql_redacted_summary(config))}"
    raise e
  end

  desc 'Look up a comment row in HiveSQL Comments by author/permlink.'
  task :comment, [:author, :permlink] do |_t, args|
    author = args[:author] || ENV['author'] || ENV['AUTHOR']
    permlink = args[:permlink] || ENV['permlink'] || ENV['PERMLINK']

    abort('Usage: rake hivesql:comment[author,permlink]') if author.to_s.empty? || permlink.to_s.empty?

    client = hivesql_client
    safe_author = author.sub(/^@/, '').gsub("'", "''")
    safe_permlink = permlink.gsub("'", "''")

    sql = <<~SQL
      SET NOCOUNT ON;
      SELECT TOP 1 *
      FROM Comments
      WHERE author = '#{safe_author}'
        AND permlink = '#{safe_permlink}';
    SQL

    result = client.execute(sql)
    row = result.each(as: :hash).first

    if row.nil?
      puts "No matching row found in Comments for @#{safe_author}/#{safe_permlink}"
    else
      puts JSON.pretty_generate(row)
    end
  ensure
    client&.close
  end
end

namespace :dump do
  desc 'Dump authors.'
  task :authors do
    puts `cat _site/authors.json | jq -r '. | values[]' | sort | uniq`
  end
end
