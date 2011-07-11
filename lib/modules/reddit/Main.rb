#!/usr/bin/ruby
#

###
#
# File: Reddit.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Reddit.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

# Require DataMapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'

# Require custom Joke ADT
require 'models/Joke.rb'

# Require one way hash function for content identification
require 'digest'

# }}}


class Reddit # {{{

  # Constructor for the Reddit joke source class
  def initalize logger = nil # {{{
    raise ArgumentError, ""
    @log = logger

  end # of def initalize }}}

  # Get the jokes in the format provided to us by the reddit website (json)
  def get_jokes url # {{{
  end # }}}

  # Turns the reddit data into a Joke ADT object
  def to_joke data # {{{
  end # of to_joke }}}

end # of class Reddit }}}


