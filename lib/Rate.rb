#!/usr/bin/ruby
#


###
#
# File: Rate.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Rate.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

# Custom includes (changes object behaviors)
require 'Extensions.rb'
require 'Logger.rb'

# }}}


# The Rate class provids means to judge a joke and stores it in the profile of the user in the database
class Rate # {{{

  # Constructor
  #
  # @param  [Joke]    joke     Requires an instantiated output object of type Joke
  def initialize joke = nil # {{{
    raise ArgumentError, "Have no joke object" if( joke.nil? )

  end # of def initialize }}}

end # of class Display }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

