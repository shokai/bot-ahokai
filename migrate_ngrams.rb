#!/usr/bin/env ruby
require 'rubygems'
require 'active_record'
require File.dirname(__FILE__) + "/model_ngram.rb"

ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => 'db',
                                        :timeout => 30000
                                        )

class NgramMigration < ActiveRecord::Migration
  def self.up
    create_table(:ngrams){|t|
      t.string :a, :null => false
      t.string :b, :null => false
      t.string :c, :null => false
      t.column :count, :int, :null => false
      t.boolean :head, :null => false
      t.boolean :tail, :null => false
    }
    create_table(:urihistories){ |t|
      t.string :uri, :null => false
    }
  end
  def self.down
    drop_table :ngrams
    drop_table :urihistories
  end
end

if ARGV.size < 1 || (ARGV[0]!="up" && ARGV[0]!="down")
  begin
    Ngram.find(:all).each{ |ng|
     puts ng.to_s
    }
  rescue
    puts "couldn't connect dbfile"
  end
  puts 'usage: "ruby migrate_ngrams.rb up"  or  "ruby migrate_ngrams.rb down"'
  exit(1)
end
puts ARGV[0]
NgramMigration.migrate(ARGV[0])
