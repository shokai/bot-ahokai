#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'feed-normalizer'
require 'MeCab'
require 'twitter'
require 'kconv'

module Buzzwords
  @uri = 'http://buzztter.com/ja/rss'

  def Buzzwords.count(words, type=/名詞/)
    mecab = MeCab::Tagger.new('-Ochasen')
    counts = Hash.new(1)
    words.each{ |w|
      mecab.parse(w).each{|ps|
        word = ps.split(/\t/)[0]
        counts[word] += 1 if word.size>3 && !(word =~ /EOS/) && ps.split(/\t/)[3] =~ type
      }
    }
    return counts
  end
  
  def Buzzwords.count_buzztter(type=/名詞/)
    begin
      feed = FeedNormalizer::FeedNormalizer.parse open(@uri)
    rescue
      puts 'feed fetch error!'
      return Array.new
    end
    puts "fetch #{@uri}"
    
    words = feed.entries.map{ |e|
      e.description
    }
    return Buzzwords.count(words)
  end
  
  def Buzzwords.count_friends(user, pass, type=/名詞/)
    httpAuth = Twitter::HTTPAuth.new(user,pass)
    twitter = Twitter::Base.new(httpAuth)
    words = twitter.friends_timeline.map{ |post|
      post.text
    }
    counts = Buzzwords.count(words)
    counts.delete("http")
    return counts
  end
  
end
