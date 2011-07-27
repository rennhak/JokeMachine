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


# The Rate class provids means to judge a jokes and stores it in the profile of the user in the database
class Rate # {{{

  # Constructor
  #
  # @param  [Joke]    joke     Requires an instantiated output object of type Joke
  def initialize user = nil, jokes = nil # {{{

    # Pre-condition check {{{
    raise ArgumentError, "Have no user account details" if( user.nil? )
    raise ArgumentError, "Have no jokes object" if( jokes.nil? )
    # }}}

    # Main
    
  end # of def initialize }}}

end # of class Display }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

