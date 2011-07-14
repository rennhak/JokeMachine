#!/usr/bin/ruby
#


###
#
# File: Downloader.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Downloader.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

require 'open-uri'

require 'rubygems'
require 'nokogiri'

require 'date'

# }}}


# The 
class Downloader # {{{

  # Constructor of the Downloader class
  def initialize # {{{
  end # of def initalize }}}


  # The function get retrieves the given URL content and returns it to the caller
  #
  # @param    [String]      url     Requires a string containing a uri which will be downloaded.
  # @returns  [OpenStruct]          Returns an OpenStruct containing content and many other meta information
  def get url # {{{
    # Pre-condition
    raise ArgumentError, "The function expects a string, but got a (#{url.class.to_s})" unless( url.is_a?(String) )

    # Main
    content                       = OpenStruct.new
    request                       = open( url )

    content.url                   = url
    content.content               = request.readlines
    content.content_type          = request.content_type
    content.charset               = request.charset
    content.content_encoding      = request.content_encoding
    content.last_modified         = request.last_modified
    content.date                  = DateTime.now

    # Post-condition
    raise ArgumentError, "Result should be of type OpenStruct, but is (#{content.class.to_s})" unless( content.is_a?(OpenStruct) )

    content
  end # }}}

end # of class Downloader }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

