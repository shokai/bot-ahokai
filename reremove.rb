#!/usr/bin/env ruby
require 'rubygems'
require 'kconv'
require 'yaml'
gem 'twitter'
require 'twitter'
require File.dirname(__FILE__) + '/Twitterers.rb'


config = YAML::load open(File.dirname(__FILE__) + '/config.yaml')

tws = Twitterers.new(config["user"], config["pass"])
followers = tws.followers
friends = tws.friends

twit = Twitter::Base.new(Twitter::HTTPAuth.new(config["user"], config["pass"]))


i = 0
(friends-followers).each{ |u|
  i+=1
  puts "remove #{u} (#{i}/#{(friends-followers).size})"
  begin
    twit.friendship_destroy(u)
  rescue
    puts '!remove error'
  end
  sleep 5
}
