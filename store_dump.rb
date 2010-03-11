#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + "/model_post.rb"

# 収集したpostを全部吐き出す

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )

limit = nil
limit = ARGV[0].to_i if ARGV[0].to_i > 0

if limit == nil
  posts = Post.find(:all, :order => "time DESC")
else
  posts = Post.find(:all, :limit => limit, :order => "time DESC")
end


posts.each{ |post|
  puts post.to_s
}
