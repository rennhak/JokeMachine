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



end # of class Filter }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

