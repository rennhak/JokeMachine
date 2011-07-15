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


    @log          = logger
    @config       = config

    @log.message :debug, "Created Reddit class instance"

    @url          = @config.base_url + "/" + @config.jokes_url + "/" + @config.get_json

    @jokes        = make_jokes

    to_s
  end # of def initalize }}}


  # Display jokes properly on STDOUT
  def to_s # {{{
    @jokes.each do |joke|
      puts ""
      puts "----[ #{joke.title} ]----\n\n"
      puts "#{joke.content}\n"
      puts "----[ U: #{joke.ups} ]----[ D: #{joke.downs} ]----[ S: #{joke.score} ]-----"
      puts ""
    end
  end # of def to_s }}}


  # Get the jokes in the format provided to us by the reddit website (json) and returns only the essential data to us in array form (items are hashes)
  #
  # @param    [String]    url   Needs an string argument representing the URI where to download the JSON source.
  # @returns  [Array]           Result returned is an Array ([ jokes, metadata ]) where each jokes array contains Hashes as elements, which hold the essential joke data and metadata is the output from Downloader::get.
  def get_jokes url = @url # {{{

    # Pre-condition
    raise ArgumentError, "The url argument should be of type string, but is (#{url.class.to_s})" unless( url.is_a?(String) )


    # Main
    jokes       = []

    downloader  = Downloader.new
    @log.message :info, "Downloading content from #{@url.to_s}"
    toc         = downloader.get( url )
    json        = JSON.parse( toc.content.join( "\n" ) )
    data        = json[ "data" ][ "children" ]

    data.each do |hash|
      if( hash[ "kind" ] == "t3" )
        item = hash[ "data" ]

        # Provided but not needed: 
        #
        # item[ "name"          ]   # "name"=>"t3_inire"
        # item[ "num_comments"  ] # "num_comments"=>4
        # item[ "thumbnail"     ] # "thumbnail"=>""
        # item[ "domain"        ] # "domain"=>"self.Jokes"
        # item[ "id"            ] # "id"=>"inire"
        # item[ "media"         ] # "media"=>nil
        # item[ "clicked"       ] # "clicked"=>false
        # item[ "subreddit_id"  ] # "subreddit_id"=>"t5_2qh72"
        # item[ "selftext_html" ] # "selftext_html"=>"&lt;!-- SC_OFF --&gt;&lt;div class=\"md\"&gt;&lt;p&gt;The bartender looks the grasshopper up and down for a minute until he finally says, \"you know, I'm pretty sure we have a drink named after you.\"\nThe grasshopper replies, \"Really?! You guys got a drink named Dave?!\"&lt;/p&gt;&lt;/div&gt;&lt;!-- SC_ON --&gt;"
        # item[ "levenshtein"   ] # "levenshtein"=>nil
        # item[ "media_embed"   ] #  "media_embed"=>{}
        # item[ "saved"         ] # "saved"=>false
        # item[ "created"       ] # "created"=>1310512579.0
        # item[ "hidden"        ] # "hidden"=>false
        # item[ "likes"         ] # "likes"=>nil
        # item[ "subreddit"     ] # "subreddit"=>"Jokes"
        # item[ "permalink"     ] # "permalink"=>"/r/Jokes/comments/inire/a_grasshopper_wandered_into_a_bar_and_sat_down/"
        # joke[ "score"         ] = item[ "score"         ] # "score"=>7    this is just a simple diff between ups - downs

        if( item[ "is_self"       ] )  # "is_self"=>true
          joke = Hash.new

          joke[ "url"           ] = item[ "url"           ]
          joke[ "over_18"       ] = item[ "over_18"       ] # "over_18"=>false
          joke[ "ups"           ] = item[ "ups"           ] # "ups"=>17
          joke[ "title"         ] = item[ "title"         ] # "title"=>"Rich man, Poor man"
          joke[ "author"        ] = item[ "author"        ] # "author"=>"madzkaleel"
          joke[ "created_utc"   ] = item[ "created_utc"   ] # "created_utc"=>1310500570.0
          joke[ "url"           ] = item[ "url"           ] # "url"=>"http://www.reddit.com/r/Jokes/comments/inpz3/rich_man_poor_man/"
          joke[ "selftext"      ] = item[ "selftext"      ] # "selftext"=>"The bartender looks the grasshopper up and down for a minute until he finally says, \"you know, I'm pretty sure we have a drink named after you.\" \nThe grasshopper replies, \"Really?! You guys got a drink named Dave?!\""
          joke[ "downs"         ] = item[ "downs"         ] # "downs"=>19

          jokes << joke
        else
          raise ArgumentError, "This joke is not of type 'self' but something else (#{item["is_self"].to_s})"
        end # of if( item[ "is_self" ] )
      else
        raise ArgumentError, "Seems the Reddit JSON spec has changed. Unexpected format of data structure error."
      end # of if( hash[ "kind" ] == "t3" )
    end # of data.each do |hash|

    # Post-condition
    raise ArgumentError, "Result should be of type Array, but is (#{jokes.class.to_s})" unless( jokes.is_a?( Array ) )

    [ jokes, toc ]
  end # }}}


  # The function takes the intermediate data from get_jokes and turns the content into proper joke ADT's
  #
  # @param    [Array]    data   Input needs to match the specific output from the get_jokes function.
  # @returns  [Array]           Returns an Array containing proper instanciated Joke ADT objects
  def make_jokes input = get_jokes # {{{
    # Pre-condition
    raise ArgumentError, "Expecting input to be of type Array, but it is (#{input.class.to_s})" unless( input.is_a?(Array) )

    # Main
    #
    # We expect this format currently:
    # [ jokes_array_containing_hashes, jokes_website_metadata ]
    data, metadata = *input

    jokes = []
    data.each do |j|
      jokes << to_joke( j )
    end

    # Set metadata for each joke ADT
    jokes.each do |joke|
      joke.last_modified      = metadata.last_modified
      joke.charset            = metadata.charset
      joke.content_encoding   = metadata.content_encoding
      joke.content_type       = metadata.content_type
      joke.downloaded_at      = metadata.date

      joke.content_sha1sum    = Digest::SHA1.hexdigest( joke.content )
      joke.title_sha1sum      = Digest::SHA1.hexdigest( joke.title   )
    end # jokes.each

    # Post-condition
    raise ArgumentError, "Expecting output to be of type Array, but it is (#{jokes.class.to_s})" unless( jokes.is_a?(Array) )

    jokes
  end # of make_jokes }}}


  # Turns the reddit data into a Joke ADT object
  #
  # @param    [Hash]    hash    Requires a specific hash input originating from the get_jokes function
  # @returns  [Joke]            Returns a proper instatiated Joke ADT object
  def to_joke hash # {{{
    # Pre-condition

    # Main
    joke = Joke.new

    # Each hash contains ...
    #    joke[ "over_18"       ] = item[ "over_18"       ] # "over_18"=>false
    #    joke[ "ups"           ] = item[ "ups"           ] # "ups"=>17
    #    joke[ "title"         ] = item[ "title"         ] # "title"=>"Rich man, Poor man"
    #    joke[ "author"        ] = item[ "author"        ] # "author"=>"madzkaleel"
    #    joke[ "created_utc"   ] = item[ "created_utc"   ] # "created_utc"=>1310500570.0
    #    joke[ "url"           ] = item[ "url"           ] # "url"=>"http://www.reddit.com/r/Jokes/comments/inpz3/rich_man_poor_man/"
    #    joke[ "selftext"      ] = item[ "selftext"      ] # "selftext"=>"The bartender looks the grasshopper up and down for a minute until he finally says, \"you know, I'm pretty sure we have a drink named after you.\" \nThe grasshopper replies, \"Really?! You guys got a drink named Dave?!\""
    #    joke[ "downs"         ] = item[ "downs"         ] # "downs"=>19
    
    joke.url            = hash[ "url"                 ]
    joke.over_18        = hash[ "over_18"             ]
    joke.ups            = hash[ "ups"                 ]
    joke.title          = hash[ "title"               ]
    joke.author         = hash[ "author"              ]

    date                = Time.at( hash[ "created_utc"] )
    joke.created_at     = date

    joke.content        = hash[ "selftext"            ]
    joke.downs          = hash[ "downs"               ]
    
    joke.source         = "Reddit Jokes Group"

    # Post-condition
    raise ArgumentError, "Return type needs to be of type Joke, but got (#{joke.class.to_s})" unless( joke.is_a?(Joke) )

    joke
  end # of to_joke }}}


  # The function update downloads the current data, but does not store to database yet
  # @param
  # @returns 
  def update jokes = @jokes # {{{
    
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
