#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require 'kconv'
require 'yaml'
gem 'twitter'
require 'twitter'
require File.dirname(__FILE__) + "/model_ngram.rb"
require File.dirname(__FILE__) + '/Twitterers.rb'
require File.dirname(__FILE__) + '/Buzzwords.rb'
$KCODE = 'UTF8'


def config
  if @config == nil
    @config = YAML::load open(File.dirname(__FILE__)+'/config.yaml')
    if @config["subusers"] != nil # サブアカたくさん列挙してる時、ランダムに1つ選ぶ
      u_p = @config["subusers"][rand(@config["subusers"].size)]
      @config["user"] = u_p["user"]
      @config["pass"] = u_p["pass"]
      puts "sub-user: " + @config["user"] + " selected"
    end
  end
  return @config
end
twit = Twitter::Base.new(Twitter::HTTPAuth.new(config["user"], config["pass"]))

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )


def markovStr(search=nil)
  # マルコフ連鎖
  words = Array.new
  ngs = Ngram.find(:all)
  
  if search != nil
    puts "make post with '#{search}'"
    tmp = Array.new
    ngs.each{|ng|
      tmp.push(ng) if ng.a+ng.b+ng.c =~ /#{search}/i
    }
    if tmp.size > 0
      ngs = tmp
    else
      puts "no match '#{search}'"
    end
  end
  start = ngs[rand(ngs.size)]
  
  words.push(start.a, start.b, start.c)
  puts start.to_s
  
  # 左へ伸ばす
  puts '---search left 3-grams---'
  left = start
  while left.head != true do
    begin
      ngs = Ngram.find(:all, :conditions => ["b=? and c=?", left.a, left.b])
      left = ngs[rand(ngs.size)]
      puts left.to_s
      words.unshift(left.a)
    rescue
      break
    end
  end
  
  
  # 右へ伸ばす
  puts '---search right 3-grams---'
  right = start
  50.times do
    begin
      ngs = Ngram.find(:all, :conditions => ["a=? and b=?",right.b , right.c])
      right = ngs[rand(ngs.size)]
      puts right.to_s
      words.push(right.c)
    rescue
      break
    end
    break if right.tail && 0.7 > rand
  end
  
  
  # ほぼ確実にreply先を変更する
  followers = nil
  for i in 0...words.size do
    s = words[i]
    if s =~ /(@[a-zA-Z0-9_]+)/
      if 0.9 > rand
        if followers == nil
          tws =  Twitterers.new(config["user"], config["pass"])
          followers = tws.followers
        end
        if followers.size > 0
          reply = followers[rand(followers.size)]
          followers.delete(reply)
          words[i] = "@#{reply}"
        end
      end
    end
    for i in 0...words.size-1 do
      if words[i] == '@' && words[i+1] =~ /[a-zA-Z0-9_]+/ # @とusernameが分かれている時
        if 0.9 > rand
          if followers == nil
            tws = Twitterers.new(config["user"], config["pass"])
            followers = tws.followers
          end
          if followers.size > 0
            reply = followers[rand(followers.size)]
            followers.delete(reply)
            words[i+1] = reply
          end
        end
      end
    end
  end
  
  # すごくたまにfollowerに話しかける
  if 0.02 > rand
    if followers == nil
      tws = Twitterers.new(config["user"], config["pass"])
      followers = tws.followers
    end
    if followers.size > 0
      reply = followers[rand(followers.size)]
      followers.delete(reply)
      words.unshift("@#{reply}")
    end
  end
  
  # String化
  post = ''
  words.each{|s|
    post += ' ' if post =~ /[a-zA-Z]\Z/ && s =~ /\A[a-zA-Z]/ # 英単語はスペース開けて連結
    if post =~/@\Z/ && s =~ /[a-zA-Z]/ # @replyが、@とusernameに分かれていた時
      post += s + ' '
      next
    end
    if s =~ /(@[a-zA-Z0-9_]+)/ # @reply
      post += ' ' if post.last != ' '
      post += s + ' '
    else
      post += s
    end
  }
  
  return post.strip.to_s
end

def has_ngWord(post)
  ngwords = Array.new
  open(File.dirname(__FILE__)+"/ngwords").read.each{ |line|
    ngwords.push(line.chomp)
  }
  ngwords.each{ |w|
    if post =~ /#{w}/
        return true
    end
  }
  return false
end

# 検索語
search = ARGV.shift
if config["blockngwords"] && has_ngWord(search)
  puts 'the search word is NG word.'
  search = nil
end

# buzztterかFriendsTimelineから名詞のみ抽出
buzzratio = config["buzzratio"] || 0.3
if search == nil && rand < buzzratio
  if rand < 0.5
    puts 'search buzztter...'
    nouns = Buzzwords.count_buzztter(/名詞/) # 単語と出現回数
  else
    puts 'search friends_timeline...'
    nouns = Buzzwords.count_friends(config["user"], config["pass"], /名詞/)
  end
  nouns2 = Array.new # 出現数が1番多い単語
  nouns.each{ |key,value|
    nouns2.push(key) if value == nouns.values.max
  }
  search = nouns2[rand(nouns2.size)]
end

post = markovStr(search).toutf8
if config["blockngwords"]
  for i in 1..10 do
    break if !has_ngWord(post)
    puts "NG! #{post}"
    puts "remake markovString (#{i})"
    post = markovStr(search).toutf8
    if i >= 10 # remakeあきらめる
      puts 'couldn\'t make markov string.'
      exit(1)
    end
  end
end
twit.update(post) if config["nopost"] == nil
puts post
