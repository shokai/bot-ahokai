#!/usr/bin/env ruby
require 'rubygems'
require 'kconv'
require 'yaml'
gem 'twitter'
require 'twitter'
require 'feed-normalizer'
require 'cgi'

config = YAML::load open(File.dirname(__FILE__)+'/config.yaml')

user = config["user"]
pass = config["pass"]
twit = Twitter::Base.new(Twitter::HTTPAuth.new(user, pass))

max = 10
max = ARGV[0].to_i if ARGV[0].to_i > 0

favlist = Array.new
searchwords = config["searchwords"].map{ |w| # Twitter Search
  CGI.escape(w)
}

for search in searchwords
  for page in 1..max
    uri = "http://search.twitter.com/search.atom?q=#{search}&page=#{page}"
    begin
      feed = FeedNormalizer::FeedNormalizer.parse open(uri)
    rescue
      puts "page #{page} fetch error!"
      next
    end
    puts uri
    feed.entries.each{ |e|
      url = e.urls.first
      if !(url =~ /\/#{user}\//) # 自分のpostで無い時
        id = url.split(/\//).last
        puts url
        favlist.push(id)
      end
    }
    sleep 10
  end
end
favlist.uniq!

# 既にfavしているものを除去
favs = twit.favorites
favs.each{ |fav|
  favlist.delete(fav.id)
}


favlist.each{ |id|
  puts "create_favorite "+id
  begin
    twit.create_favorite(id)
  rescue
    puts "fav error!"
  end
  sleep 10
}


