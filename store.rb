#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require 'feed-normalizer'
require 'open-uri'
require 'kconv'
require 'yaml'
require File.dirname(__FILE__) + "/model_post.rb"

config = YAML::load open(File.dirname(__FILE__)+'/config.yaml')

user = config["usernum"] # twitterID
if user == nil
  puts 'Error!: usernum not Found on config.yaml'
  exit(1)
end

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )

last = 10
last = ARGV[0].to_i if ARGV[0].to_i > 0
first = 1
first = ARGV[1].to_i if ARGV[1].to_i > 0

errors = Array.new
for page in first..last
  uri = "http://twitter.com/statuses/user_timeline/#{user}.atom?page=#{page}"
  begin
    if(config["user"] != nil && config["pass"] != nil)
      feed = FeedNormalizer::FeedNormalizer.parse open(uri, :http_basic_authentication => [config["user"], config["pass"]])
    else
      feed = FeedNormalizer::FeedNormalizer.parse open(uri)
    end
    
  rescue
    puts "feed fetch error! page:#{page}"
    errors.push(page)
    sleep 10
    next
  end
  
  puts uri
  feed.entries.each{ |e|
    if Post.find_by_uri(e.url) == nil
      post = Post.create(:uri => e.url,
                  :message => e.content.gsub(/&#(?:(\d*?)|(?:[xX]([0-9a-fA-F]{4})));/) { [$1.nil? ? $2.to_i(16) : $1.to_i].pack('U') },
                  :time => e.last_updated
                  )
      puts post
    end
  }
  puts "-----page:#{page} (#{first}-#{last}) finished-----"
  sleep 10 if page < last
end

if errors.size > 0
  print "feed fetch error at page:"
  puts errors.join(' ')
end
