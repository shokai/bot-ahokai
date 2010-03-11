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
(followers-friends).each{ |u|
  i+=1
  puts "follow #{u} (#{i}/#{(followers-friends).size})"
  begin
    twit.friendship_create(u)
  rescue
    puts '!follow error'
  end
  sleep 5
}


