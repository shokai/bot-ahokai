#!/usr/bin/env ruby
require 'rubygems'
require 'MeCab'
require 'active_record'
require 'kconv'
require File.dirname(__FILE__) + "/model_post.rb"
require File.dirname(__FILE__) + "/model_ngram.rb"


ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )

mecab = MeCab::Tagger.new('-Ochasen')

messages = Hash.new
Post.find(:all).each{ |post|
  messages[post.uri] = post.message
}

messages.each{ |uri, message|
  puts message
  if Urihistory.find(:first, :conditions => ["uri=?", uri]) != nil
    next
  end
  
  # user名を削除
  message = message.split(/: /)
  message.shift
  message = message.join('')

  # URLの前までを切り出し
  tmp = message.split(/(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/)
  next if tmp.first =~ /(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/
  message = tmp.first
  
  # @reply以外をmecabで分かち書き
  words = Array.new
  at_reply = /(@[a-zA-Z0-9_]+)/ # @replyにマッチ
  message.split(at_reply).each{|s|
    if s =~ at_reply
      words.push(s)
    else
      mecab.parse(s).each{|ps|
        w = ps.split(/\t/)[0]
        words.push(w) if !(w =~ /EOS/)
      }
    end
  }
  
  # 3-gramを作成
  ngs = Array.new
  for i in 0..words.size-3
    head = (i == 0)
    tail = (i == words.size-3)
    a,b,c = words[i..i+2] # 3-gram
    ng = Ngram.find(:first, :conditions => ["a=? and b=? and c=?", a, b, c])
    if ng != nil
      ng.count += 1
      ng.head = head
      ng.tail = tail
      ngs.push(ng)
    else
      ng = Ngram.new(:a => a,
                     :b => b,
                     :c => c,
                     :count => 1,
                     :head => head,
                     :tail => tail)
      ngs.push(ng)
    end
    puts ng.to_s
  end
  ngs.each{|ng|ng.save}
  Urihistory.create(:uri => uri)
}

