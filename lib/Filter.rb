#!/usr/bin/ruby
#


###
#
# File: Filter.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Filter.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

require 'rubygems'
require 'classifier'

# Custom includes (changes object behaviors)
require 'Extensions.rb'
require 'Logger.rb'

require 'models/Joke.rb'
require 'models/User.rb'
require 'models/Vote.rb'

# }}}


class Filter # {{{

  # Constructor
  #
  # @param  [Joke]    joke     Requires an instantiated output object of type Joke
  def initialize options = nil, username = nil, jokes = nil # {{{

    # Pre-condition check {{{
    raise ArgumentError, "Have no options object" if( options.nil? )
    raise ArgumentError, "Have no user account details" if( username.nil? )
    raise ArgumentError, "Have no jokes object" if( jokes.nil? )
    # }}}

    # Main
    @log                      = Logger.new( options )
    @username                 = username
    @jokes                    = jokes

  end # of def initialize }}}

  def train

    funny_joke_votes          = Vote.all( :fields => [:joke_id], :username => @username, :percent.gt => 50 )
    unfunny_joke_votes        = Vote.all( :fields => [:joke_id], :username => @username, :percent.lt => 50 )
    funny_joke_ids            = []
    unfunny_joke_ids          = []

    funny_joke_votes.each { |j| funny_joke_ids << j.joke_id.to_i }
    unfunny_joke_votes.each { |j| unfunny_joke_ids << j.joke_id.to_i }

    funny                     = []
    unfunny                   = []

    funny_joke_ids.each do |jid|
      funny << Joke.all( :id => jid )
    end

    unfunny_joke_ids.each do |jid|
      unfunny << Joke.all( :id => jid )
    end


    funny.flatten!
    unfunny.flatten! 

    b = Classifier::Bayes.new 'funny', 'unfunny'

    @log.message :info, "Training funny jokes (amount: #{funny.length.to_s})"
    funny.each do |joke|
      content = joke.title.to_s + joke.content.to_s
      b.train_funny content
    end

    @log.message :info, "Training unfunny jokes (amount: #{unfunny.length.to_s})"
    unfunny.each do |joke|
      content = joke.title.to_s + joke.content.to_s
      b.train_unfunny content
    end

    result = []
    
    Joke.all.each do |joke|
      content = joke.title.to_s + joke.content.to_s
      type    = b.classify content

      if( type.downcase == "funny" )
        result << joke 
      end
    end
  
    result
  end 



end # of class Filter }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

