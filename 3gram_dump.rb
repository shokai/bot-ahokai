#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + "/model_ngram.rb"

# 作成した3-gram辞書を全部吐き出す

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )

limit = nil
limit = ARGV[0].to_i if ARGV[0].to_i > 0

if limit == nil
  ngrams = Ngram.find(:all, :order => "count DESC") # 出現回数順
else
  ngrams = Ngram.find(:all, :limit => limit, :order => "count DESC")
end


ngrams.each{ |ng|
  puts ng.to_s
}

