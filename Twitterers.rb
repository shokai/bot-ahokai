#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'rexml/document'
require 'kconv'

class Twitterers

  def initialize(user,pass)
    @user = user
    @pass = pass
  end
  
  def followers
    puts 'getting followers list'
    get_users("http://twitter.com/statuses/followers.xml", 10)
  end
  
  def friends
    puts 'getting friends list'
    get_users("http://twitter.com/statuses/friends.xml", 10)
  end
  
  def get_users(uri, max_page=10)
    results = Array.new
    
    for page in 1..max_page
      print "reading page#{page}..."
      begin
        page = open(uri.to_s+'?page='+page.to_s,
                    :http_basic_authentication => [@user, @pass]).read()
      rescue
        puts "error!"
        sleep 10
        next
      end
      break if (page =~ /<user>/) == nil
      doc = REXML::Document.new(page)
      REXML::XPath.each(doc, '//user/screen_name()'){ |name|
        results.push(name.text)
      }
      puts " #{results.length} users"
      sleep 10
    end
    puts 'finished!'
    return results
  end
  
end

