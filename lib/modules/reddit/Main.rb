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

# Handle Reddit Data format
require 'json'

# Require custom Joke ADT
require 'models/Joke.rb'

# Require one way hash function for content identification
require 'digest'

require 'Downloader.rb'


# }}}


# The class Reddit takes care of the data handling from the reddit site to our database.
class Reddit # {{{

  # Construcoptionstor for the Reddit joke source class
  #
  # @param [Logger]       logger
  # @param [OpenStruct]   config
  def initialize logger = nil, config = nil # {{{
    raise ArgumentError, "Need a valid logger instance" if( logger.nil? )
    raise ArgumentError, "Need a valid config instance" if( config.nil? )


    @log        = logger
    @config     = config

    @log.message :debug, "Created Reddit class instance"

    @url        = @config.base_url + "/" + @config.jokes_url + "/" + @config.get_json
    @log.message :info, "Downloading content from #{@url.to_s}"

    p get_jokes
  end # of def initalize }}}


  # Get the jokes in the format provided to us by the reddit website (json)
  def get_jokes url = @url # {{{
    # Pre-condition

    # Main
    downloader  = Downloader.new
    toc         = downloader.get( url )

    p JSON.parse( toc.content.join( "\n" ) )

    # Post-condition
  end # }}}


  # Turns the reddit data into a Joke ADT object
  def to_joke data # {{{
  end # of to_joke }}}


  # The function update downloads the current data, but does not store to database yet
  # @param
  # @returns 
  def update # {{{
  end # of def update }}}


  # The function update downloads the current data and stores it in the database
  # @param 
  # @returns
  def update! # {{{
  end # of def update! }}}

end # of class Reddit }}}


# Direct invocation 
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}
