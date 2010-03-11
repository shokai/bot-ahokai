#!/usr/bin/env ruby
require 'rubygems'
require 'MeCab'
require 'active_record'
require 'kconv'
require File.dirname(__FILE__) + "/model_ngram.rb"

files = Array.new
ARGV.each{|arg|
  if File.exists?(arg)
    files.push(arg)
  else
    puts arg+" Not Found"
  end
}

if files.size < 1
  puts '!!put file name'
  puts 'usage:  ruby make3gram_fromtextfile.rb dictionary.txt chatlog.txt'
  puts '        ruby make3gram_fromtextfile.rb dic/*.text'
  exit(1)
end


puts '-----start-----'


mecab = MeCab::Tagger.new('-Ochasen')


ActiveRecord::Base.establish_connection(
                                        :adapter => 'sqlite3',
                                        #:dbfile => ':memory:',
                                        :dbfile => File.dirname(__FILE__) + '/db',
                                        :timeout => 30000
                                        )


files.each{|file|
  open(file).each{|line|
    tmp = line.toutf8.split(/(。|．|？|\?)/)
    messages = Array.new
    while tmp.size > 0 do
      messages.push tmp.shift.to_s+tmp.shift.to_s
    end
    messages.each{|message|
      next if message =~ /(https?\:[\w\.\~\-\/\?\&\+\=\:\@\%\;\#\%]+)/
      puts message
      words = Array.new
      mecab.parse(message).each{|s|
        w = s.split(/\t/)[0]
        words.push(w) if !(w =~ /EOS/)
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
      puts '-------'
    }
    
    puts '*********'
  }
}


