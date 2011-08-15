#!/usr/bin/ruby
#

###
#
# File: Main.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Main.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

# Require DataMapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'

# Handle eBaumsworld Data format
require 'nokogiri'

# Require custom Joke ADT
load 'models/Joke.rb'

# Require one way hash function for content identification
require 'digest'

load 'Downloader.rb'

# }}}


# The class Jokes4all takes care of the data handling from the Jokes4all site to our database.
class Ebaumsworld # {{{

  # Construcoptionstor for the Ebaumsworld joke source class
  #
  # @param [Logger]       logger
  # @param [OpenStruct]   config
  # @param [String]       db_type This string represents the db connector used for DataMapper, e.g. "sqlite3"
  # @param [String]       db_path This string represents the db path used for DataMapper, e.g. "data/database/foo.sqlite3"
  def initialize options = nil, logger = nil, config = nil, db_type = nil, db_path = nil # {{{
    raise ArgumentError, "Need a valid logger instance" if( logger.nil? )
    raise ArgumentError, "Need a valid config instance" if( config.nil? )
    # raise ArgumentError, "db_type needs to be of type string" unless( db_type.is_a?( String ) )
    # raise ArgumentError, "db_path needs to be of type string" unless( db_path.is_a?( String ) )

    @options      = options
    @log          = logger
    @config       = config

    @log.message :debug, "Created Ebaumsworld class instance"

    @db_type, @db_path  = db_type, db_path
    data_mapper_init( "sqlite3", "data/databases/test.sqlite3", true ) if( @db_type.nil? or @db_path.nil? )

    @urls                   = []

    @last_page              = 1
    @urls                   << @config.base_url + "/" + @config.jokes_url + @last_page.to_s

    @jokes                  = []


  end # of def initalize }}}


  # Data_mapper_init takes a db type and path and initializes the database in case we want to execute this object directly and have no DB give from JokeMachine main class.
  # @param [String] db_type Type of the database connector used, eg. sqlite3
  # @param [String] db_path Path of the database, eg. databases/test.sqlite3
  # @param [Boolean] logging Turns DataMapper logging on or off
  def data_mapper_init db_type = "sqlite3", db_path = "data/databases/test.sqlite3", logging = false # {{{
    # DataMapper::Logger.new( $stdout, :debug ) if( logging )

    db_connector = "#{db_type}://#{Dir.pwd}/#{db_path}"

    @log.message :info, "We don't have any DataMapper init info, so we will create a new database at #{db_connector.to_s} (./reddit/Main.rb)"
    DataMapper.setup( :default, db_connector )


    # DataMapper.auto_migrate! # wipes out db
    DataMapper.auto_upgrade! # trys to keep data
    DataMapper.finalize
  end # }}}


  # Display jokes properly on STDOUT
  def to_s # {{{
    @jokes.each do |joke|
      puts ""
      puts "----[ #{joke.title} ]----\n\n"
      puts "#{joke.content}\n"
      puts "----[ U: #{joke.ups} ]----[ D: #{joke.downs} ]---------"
      puts ""
    end
  end # of def to_s }}}


  # Get the jokes in the format provided to us by the reddit website (json) and returns only the essential data to us in array form (items are hashes)
  #
  # @param    [String]    url   Needs an string argument representing the URI where to download the JSON source.
  # @returns  [Array]           Result returned is an Array ([ jokes, metadata ]) where each jokes array contains Hashes as elements, which hold the essential joke data and metadata is the output from Downloader::get.
  def get urls = @urls # {{{

    # Pre-condition
    raise ArgumentError, "The urls argument should be of type Array, but is (#{urls.class.to_s})" unless( urls.is_a?(Array) )

    # Main
    jokes       = []
    final       = []

    downloader  = Downloader.new
    toc         = []

    urls.each do |url|
      @log.message :info, "Downloading content from #{url.to_s}"
      response    = downloader.get( url )
      toc         << response
    end

    toc.each do |r|
      jokes.clear

      # Lets get the links to the jokes
      html              = Nokogiri::HTML( r.content.to_s )
      content           = []


      # Extract links to jokes and title of jokes on this page
      html.xpath( "//div[@class='medialisting']/ul" ).each_with_index do |node, i|
        tmp               = OpenStruct.new

        # Extract topic and link
        Nokogiri::HTML( node.to_s ).xpath( "//li[@class='details']/p/a" ).each do |n|
          tmp.title       = n.inner_text
          tmp.link        = n['href'] 
        end

        # Extract author and other metadata
        Nokogiri::HTML( node.to_s ).xpath( "//li[@class='medialistingstats']/p/a" ).each do |n|
          tmp.user        = n.inner_text.to_s.strip
        end

        content << tmp
      end # of html.xpath

      # Extract content of each link
      content.collect! do |item| # {{{
        title, link, user   = item.title, item.link, item.user

        # Skip downloading jokes we already stored in the DB
        j_query = Joke.all( :title    => title, :author => user )

        unless( j_query.empty? )
          @log.message :debug, "Skipping ,,#{title.to_s}'' since we already have that in the DB"

          nil
        else
          @log.message :debug, "Downloading joke #{link.to_s}"
          response = downloader.get( link )

          Nokogiri::HTML( response.content.to_s ).xpath( "//div[@id='mediaContentSection']" ).each do |node|
            item.content = node.inner_text
          end

          @log.message( :info, "Mandatory sleep between requests (#{@config.refresh_delay.to_s}s)" )
          if( @options.random_intervals )
            sleep @config.refresh_delay.to_i
          else
            sleep ( @config.refresh_delay.to_i + rand( @options.random_interval_time ) )
          end

          item
        end

      end # of content.each # }}}

      # Get rid of nil's
      content.compact!

      # content.each do |a|
      #  printf( "%20s %40s %40s %50s\n\n", a.user, a.link, a.title, a.content )
      # end

      # Create Joke object
      content.each do |item|
        title, link, user, content    = item.title, item.link, item.user, item.content
        url                           = item.link

        date                          = DateTime.now  # eBaum's time measurement is weird. lets skip this for now
        uploaded                      = Time.parse( date.to_s ).utc

        joke = Hash.new

        joke[ "joke_id"       ] = ""
        joke[ "url"           ] = url
        joke[ "over_18"       ] = false # "over_18"=>false
        joke[ "title"         ] = title # "title"=>"Rich man, Poor man"
        joke[ "created_utc"   ] = uploaded

        joke[ "ups"           ] = 0 # "ups"=>17
        joke[ "author"        ] = user # "author"=>"madzkaleel"
        joke[ "selftext"      ] = content  # "selftext"=>"The bartender looks the grasshopper up and down for a minute until he finally says, \"you know, I'm pretty sure we have a drink named after you.\" \nThe grasshopper replies, \"Really?! You guys got a drink named Dave?!\""
        joke[ "downs"         ] = 0 # "downs"=>19

        jokes << joke
      end

      final << [jokes, r]
    end # of toc.each

    # Post-condition
    raise ArgumentError, "Result should be of type Array, but is (#{jokes.class.to_s})" unless( jokes.is_a?( Array ) )

    final
  end # of get }}}


  # The function takes the intermediate data from get_jokes and turns the content into proper joke ADT's
  #
  # @param    [Array]    inputs Input needs to match the specific output from the get_jokes function.
  # @returns  [Array]           Returns an Array containing proper instanciated Joke ADT objects
  def make inputs = get # {{{
    # Pre-condition
    raise ArgumentError, "Expecting input to be of type Array, but it is (#{inputs.class.to_s})" unless( inputs.is_a?(Array) )

    # Main
    #
    # We expect this format currently:
    # [ [ jokes_array_containing_hashes, jokes_website_metadata ], ...] 
    result = []

    inputs.each do |input|
      data, metadata = *input

      jokes = []
      data.each do |j|
        jokes << to_joke( j )
      end # of data.each

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

      result.concat( jokes )

    end # of inputs.each

    # Post-condition
    raise ArgumentError, "Expecting output to be of type Array, but it is (#{result.class.to_s})" unless( result.is_a?(Array) )

    result
  end # of make }}}


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
    
    joke.joke_id        = hash[ "joke_id"             ]
    joke.url            = hash[ "url"                 ]
    joke.over_18        = hash[ "over_18"             ]
    joke.ups            = hash[ "ups"                 ]
    joke.title          = hash[ "title"               ]
    joke.author         = hash[ "author"              ]

    date                = Time.at( hash[ "created_utc"] )
    joke.created_at     = date

    joke.content        = hash[ "selftext"            ]
    joke.downs          = hash[ "downs"               ]
    
    joke.source         = "eBaum's World Jokes"

    # Post-condition
    raise ArgumentError, "Return type needs to be of type Joke, but got (#{joke.class.to_s})" unless( joke.is_a?(Joke) )

    joke
  end # of to_joke }}}


  # The function takes the downloaded jokes and checks against the database if the jokes are already there
  #
  # @param    [Array]   jokes     Requires an Array containing properly instantiated Joke ADT objects
  # @returns  [Array]             Returns Array containing jokes which currently don't exist in the Database
  def remove_existing jokes = @jokes # {{{

    # Pre-condition
    raise ArgumentError, "The input of this function should be an Array, but is of type (#{jokes.class.to_s})" unless( jokes.is_a?( Array ) )

    # Main
    jokes.collect! do |joke|
      title_sha1sum   = joke.title_sha1sum
      content_sha1sum = joke.content_sha1sum

      t_query = Joke.all( :title_sha1sum    => title_sha1sum    )
      c_query = Joke.all( :content_sha1sum  => content_sha1sum  )
      
      remove = false

      if( t_query.empty? )

        # the joke title doesn't exist in the DB
        if( c_query.empty? )
          # joke title & content doesn't exist in DB
          remove = false
        else
          # joke title => no ; joke content => yes (duplicate joke)
          remove = true
        end # of if( c_query.empty?) 

      else # of if( t_query.empty? )

        # the joke title exists in the DB
        if( c_query.empty? )
          # joke title => yes & content doesn't exist in DB (variation of the joke?)
          remove = false 
        else
          # joke title => yes ; joke content => yes
          remove = true
        end # of if( c_query.empty?) 
      end # of if( t_query.empty? )

      @log.message :debug, "Removing title: '#{joke.title.chomp.to_s}' from the jokes list (found it already in the DB)" if( remove )
      ( remove ) ? ( nil ) : ( joke )
    end # of jokes.collect! do

    jokes.compact!

    # Post-condition
    raise ArgumentError, "The result of this function should be an Array, but is of type (#{jokes.class.to_s})" unless( jokes.is_a?( Array ) )

    jokes
  end # }}}


  # The function stores the current data to the database
  #
  # @param    [Array]     jokes     Requires an Array containing properly instantiated Joke ADT objects
  # @returns  [Boolean]             Success if true, false if it couldn't be stored in the database
  def store! jokes = @jokes # {{{
    # Pre-condition
    raise ArgumentError, "The input of this function should be an Array, but is of type (#{jokes.class.to_s})" unless( jokes.is_a?( Array ) )

    # Main
    success = false

    @log.message :info, "Storing #{jokes.length} into the DB"

    jokes.each do |joke|
      success = joke.save
      unless( success )
        puts "Couldn't save #{joke.url.to_s} to the Database (title sha1: #{joke.title_sha1sum.to_s})" 
        #break
      end
    end

    success
  end # of def update! }}}


  # The function takes a number and retrieves a that many jokes from the jokes pages (or until there is nothing left)
  #
  # @param    [Integer]     amount    Expects an integer of the amount of jokes to retrieve 1-n
  def update amount = 25 # {{{

    # Pre-condition check
    raise ArgumentError, "Download amount may not be nil" if( amount.nil? )
    raise ArgumentError, "Download amount of type integer expected, but got (#{amount.class.to_s})" unless( amount.is_a?( Integer ) )

    # First iteration or not?
    while( amount > 0 )

      if( ( @jokes.empty? ) and ( @last_page == 1 ) )
        @jokes        = make
        @last_page   += 1
      else
        url           = @config.base_url + "/" + @config.jokes_url + @last_page.to_s
        tmp           = make( get( [ url ] ) )
        @jokes.concat( tmp )
        @last_page   += 1
      end

      amount -= 24  # there are 24 items on one page normally

      if( amount > 0 )
        if( @options.random_intervals )
          delay = @config.refresh_delay.to_i
        else
          delay = ( @config.refresh_delay.to_i + rand( @options.random_interval_time ) )
        end

        @log.message :warning, "Mandatory refresh delay between requests, sleeping for #{delay.to_s} seconds"

        sleep delay
      end
    end

    @jokes        = remove_existing( @jokes )
  end # of def update }}}


  # The function takes a number and retrieves a that many jokes from the jokes pages (or until there is nothing left)
  #
  # @param    [Integer]     amount    Expects an integer of the amount of jokes to retrieve 1-n
  def update! amount = 25  # {{{
    update( amount )
    store!
  end # of def update! }}}

end # of class Ebaumsworld }}}


# Direct invocation 
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

