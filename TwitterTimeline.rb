#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'feed-normalizer'
require 'kconv'

class TwitterAPI

  def initialize(user,pass)
    @user = user
    @pass = pass
  end
  
  def replies(start_page=1, end_page=1)
    puts 'getting replies'
    get_api("http://twitter.com/replies.atom", start_page, end_page)
  end
  
  def friends_timeline(start_page=1, end_page=1)
    puts 'getting friends_timeline'
    get_api("http://twitter.com/statuses/friends_timeline.atom", start_page, end_page)
  end
  
  def public_timeline(start_page=1, end_page=1)
    puts 'getting public_timeline'
    get_api("http://twitter.com/statuses/public_timeline.atom", start_page, end_page)
  end
  
  def get_api(uri, start_page, end_page)
    entries = Array.new
    for page in start_page..end_page
      print "reading page#{page}..."
      begin
        page = open(uri.to_s+'?page='+page.to_s,
                    :http_basic_authentication => [@user, @pass]).read()
        feed = FeedNormalizer::FeedNormalizer.parse(page)
        feed.entries.each{ |e|
          entries.push(e)
        }
      rescue
        puts "fetch feed error!"
        sleep 4
        next
      end
      sleep 4
      puts 'success'
    end
    entries.each{ |e|
      e.content.gsub!(/&#(?:(\d*?)|(?:[xX]([0-9a-fA-F]{4})));/) { [$1.nil? ? $2.to_i(16) : $1.to_i].pack('U') }
    }
    puts entries.size.to_s+'entries'
    return entries
  end
  
end

