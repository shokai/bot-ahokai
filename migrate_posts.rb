#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + "/model_post.rb"

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => 'db',
                                        :timeout => 30000
                                        )

class PostMigration < ActiveRecord::Migration
  def self.up
    create_table(:posts){|t|
      t.string :message, :null => false
      t.string :uri, :null => false
      t.time :time, :null => false
    }
  end

  def self.down
    drop_table :posts
  end
end

if ARGV.size < 1 || (ARGV[0]!="up" && ARGV[0]!="down")
  begin
    Post.find(:all).each{ |post|
      puts post.to_s
    }
  rescue
    puts "couldn't connect dbfile"
  end
  puts 'usage: "ruby migrate.rb up"  or  "ruby migrate.rb down"'
  exit(1)
end

PostMigration.migrate(ARGV[0])
