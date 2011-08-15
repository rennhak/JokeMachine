#!/usr/bin/env ruby
#


###
#
# File: JokeMachine.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       JokeMachine.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

# OptionParser related
require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'
require 'date'

# Standard includes
require 'rubygems'

# Require DataMapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'

# Custom includes (changes object behaviors)
load 'Extensions.rb'
load 'Logger.rb'
load 'Display.rb'
load 'Rate.rb'
load 'Filter.rb'

# Require custom Joke ADT for searching
load 'models/Joke.rb'
load 'models/Website.rb'
load 'models/User.rb'

# }}}


# The JokeMachine class controls the aquisition and display and rating of jokes.
class JokeMachine # {{{

  # Constructor of the JokeMachine class
  #
  # @param [OpenStruct] options   Requires an OpenStruct object with the result of the ARGV processing (JokeMachine::parse_cmd_arguments)
  def initialize options = nil # {{{
    @options = options

    @log     = Logger.new( @options )

    # Minimal configuration
    @config                       = OpenStruct.new
    @config.os                    = "Unknown"
    @config.platform              = "Unknown"
    @config.encoding              = "UTF-8"
    @config.archive_dir           = "archive"
    @config.database_dir          = "data/database"
    @config.config_dir            = "configurations"
    @config.cache_dir             = "cache"
    @config.db_connector          = ""
    @config.db_type               = ""
    @config.db_path               = ""

    # Determine which configs are available
    @configurations       = Dir[ "#{@config.config_dir}/*.yaml" ].collect { |d| d.gsub( "#{@config.config_dir}/", "" ).gsub( ".yaml", "" ) }

    unless( options.nil? )
      @log.message :success, "Starting #{__FILE__} run"
      @log.message :debug,   "Colorizing output as requested" if( @options.colorize )
      @log.message :debug,   "Using random intervals when polling as requested" if( @options.random_intervals )

      ####
      # Main Control Flow
      ##########

      # DataMapper
      @config.db_path, @config.db_type = @options.db_path, @options.db_type
      @config.db_connector = "#{@options.db_type}://#{Dir.pwd}/#{@options.db_path}"
      @log.message :info, "Setting up DataMapper (#{@config.db_connector.to_s})"
      data_mapper_init

      # Go through each module for updates
      unless( @options.process.empty? )
        if( @options.automatic )
          while true
            update_modules
            @log.message :info, "Sleeping #{@options.interval.to_s} seconds (#{@options.interval.to_f/(60*60)} hours)"
            joke_count.to_a.sort.each { |source, count| printf( "%-20s | %6i\n", source, count ) }
            sleep @options.interval
          end
        else
          @log.message :info, "Updating given modules only ONCE"
          update_modules
        end
      end # of unless( @options.process.empty? )

      # Limit to certain joke sources 
      if( @options.sources.empty? )
        @jokes                    = ( Joke.all ).reverse
      else
        # We should use only specific sources
        @jokes = []

        @options.sources.each do |config_file|
          c                         = read_config( @config.config_dir + "/" + config_file + ".yaml" )
          db_source_tag             = c.db_source_tag

          @jokes                    << Joke.all( :source => db_source_tag ).to_a
          @log.message :debug, "Adding #{db_source_tag} to jokes result"
          @jokes.flatten!
        end
      end

      # This should maybe be in a client app instead
      if( @options.read )
        unless( @options.username == "" )
          @filter                   = Filter.new( @options, @options.username, @jokes )
          @jokes                    = @filter.train
        end

        @display                  = Display.new( @jokes )
        @display.to_stdout
      end

      # This should be in a client app instead
      if( @options.rate )
        if( @options.username == "" )
          @log.message :error, "Have no valid username, please provide one with the -u option"
          raise ArgumentError, "Need a username"
        end # of if( @options.username == "" )

        @log.message :info, "Rating jokes for the user account '#{@options.username}'"
        @rate                     = Rate.new( @options, @options.username, @jokes )
        @rate.unrated

      end # of if( @options.rate )

      # Input joke manually
      if( @options.manual_input )
        while( true )
          manual_input
          answer = get_choice_from_bipolar( "More input?" )
          break unless( answer )
        end
      end # of if( @options.manual_input )

      if( @options.joke_count )
        puts "Currently we have >> #{Joke.all.length.to_s} << jokes in the database.\n"
        joke_count.to_a.sort.each { |source, count| printf( "%-20s | %6i\n", source, count ) }
      end
    end # of unless( options.nil? )
  end # of def initalize }}}


  # The function count goes through the jokes database and counts the jokes according to their source
  #
  # @returns  [Hash]      Returns a hash with "Total" and all other sources and their corresponding joke count
  #
  # FIXME: Use a proper SQL query for this.
  def joke_count # {{{

    @log.message :debug, "Entering count function"

    jokes                               = Joke.all
    sources                             = Hash.new

    sources[ "Total" ]                  = jokes.length
    sources[ "Manually Entered" ]       = 0

    jokes.each do |j|
      source                            = j.source

      if( source == nil )
        sources[ "Manually Entered" ]  += 1
      else
        sources[ source ]               = 0 if sources[ source ].nil?
        sources[ source ]              += 1
      end
    end

    sources
  end # of def count }}}


  # The function handles when a user wants to input a joke directly via the CLI
  #
  # @returns  [Joke]      Returns a newly created joke object with the joke input data added
  def manual_input # {{{

    # Convenience shorthand 
    yellow = Proc.new { |m| @log.colorize( "Yellow", m.to_s ) }

    STDOUT.flush
    #$/ = '\r\n'

    # Aquire data
    puts yellow.call( "\n>> Please type your [[ JOKE ]] here and after you are finished hit CTRL+D twice\n" )

    # The method over the re-def over $/ = "END" works too, but mangles later STDIN.gets somehow - why?
    joke = ""
    while true
      begin
        input = STDIN.sysread(1)
        joke += input
      rescue EOFError
        break
      end
    end

    puts yellow.call( ">> TITLE of this joke: " )
    title = STDIN.readline.chomp

    puts yellow.call( ">> URL where you found this joke (Press enter to accept previous URL: #{@_prev_url.to_s}): " )
    url = STDIN.readline
    if( url =~ %r{^\n$} )
      puts yellow.call( ">> Using previous URL ( #{@_prev_url.to_s} )" )
      url = @_prev_url 
    else
      url = url.chomp
    end

    @_prev_url = url

    puts yellow.call( ">> Who posted or authored this joke: " )
    author = STDIN.readline.chomp

    new           = Joke.new
    new.content   = joke.chomp
    new.title     = title
    new.url       = url
    new.author    = author

    puts ""
    puts "-"*30
    puts "Joke object:"
    puts ""
    p new
    puts "-"*30
    answer        = get_choice_from_bipolar( "Do you want to store this joke to Database? "  )

    if( answer ) 
      res = new.save!
      answer = ( res ) ? ( "Success !" ) : ( "Failure !" )
      puts yellow.call( answer )
    end

    new
  end # of def manual_input }}}


  # The function ask will take a simple string query it on the CMD and wait for an answer e.g. "y" (or enter)
  #
  # @param   [String]   question          String, representing the question you want to query.
  # @param   [Array]    allowed_answers   Array, representing the allowed answers
  # @returns [Boolean]                    Boolean, true for yes, false for no
  def get_choice_from_bipolar question, allowed_answers = %w[ y n ENTER ] # {{{
    print "#{question.to_s} [#{allowed_answers.join(", ")}] : "
    STDOUT.flush
    answer = STDIN.gets.to_s
    if( answer =~ %r{^\n$}i )
      answer = "enter"
    else
      answer = answer.chomp.downcase
    end

    return true  if( answer =~ %r{y|enter}i )
    return false if( answer =~ %r{n}i )
  end # of def ask }}}


  # The function updates all given modules provided from the CLI input
  #
  # @param  [Array]   processes     Requires and array containing all the modules which should be updated
  def update_modules processes = @options.process # {{{
    processes.each do |config_file|

      config_filename    = @config.config_dir + "/" + config_file + ".yaml"
      config             = read_config( config_filename )

      # Require module
      load "modules/#{config.module.to_s}/Main.rb"

      # Create instance and get new data
      instance                    = eval( "#{config.module.capitalize.to_s}.new( @options, @log, config, @config.db_type, @config.db_path )" )
      amount                      = config.download_amount

      # Do we need to wait?
      sleep_time                  = sleep?( config.module.to_s, config.refresh_delay )
      unless( sleep_time == 0 )
        @log.message :warning, "Sleeping for #{sleep_time.to_s} seconds (#{config.module.to_s}) due to mandatory refresh delay"
        sleep sleep_time 
      end

      # Update DB that we update the website now
      website                     = Website.first( :name => config.module.to_s )
      website.last_access         = Time.now
      website.save!

      # Update
      instance.update!( amount )

      @log.message :success, "Finished processing of #{config_filename.to_s}"
    end # of @options.process.each
  end # of def update_modules }}}


  # The function returns the sleep time required before another poll can be made.
  # e.g. reddits says "don't poll more often than every 30s"
  #
  # @param    [String]    module_name     Requires a string containing a valid module name (given by e.g. CLI interface)
  # @param    [Integer]   refresh_delay   Wait this uamount (in sec) at least before next refresh from last refresh (given by config file)
  # @returns  [Integer]                   Time to next refresh is possible. Is zero if refresh can be done immediately
  def sleep? module_name = nil, refresh_delay = 60 # {{{

    # Pre-condition check # {{{
    raise ArgumentError, "Module name cannot be nil, but it is" if( module_name.nil? )
    raise ArgumentError, "Module name should be of type string, but it is (#{module_name.class.to_s})" unless( module_name.is_a?(String) )
    # }}}

    # Main
    sleep_time          = 60 # make sure we always wait 60 s if we get no valid feedback

    website       = Website.first( :name => module_name )

    # We have never accessed this website so we need to create an initial DB entry
    if( website.nil? )
      new               = Website.new
      new.name          = module_name
      new.last_access   = Time.now
      new.save!
      website           = new
    end

    last_access         = Time.parse( website.last_access.to_s )

    raise ArgumentError, "last_access cannot be nil" if( last_access.nil? )
    raise ArgumentError, "last_access needs to be of type Time, but is (#{last_access.class.to_s})" unless( last_access.is_a?( Time ) )

    now           = Time.now
    diff          = ( now - last_access ).to_i

    @log.message :debug, "Sleep function result is - Now (#{now.to_s}) - Last Access (#{last_access.to_s}) - Mandatori Refresh Delay (#{refresh_delay.to_s}) - Now-Last (#{diff.to_s}) - Sleep (#{diff.to_s})"

    sleep_time    = ( diff > refresh_delay ) ? ( 0 ) : ( refresh_delay - diff )

    # Post-condition check
    raise ArgumentError, "Result of this function is supposed to be of type integer, but is (#{sleep_time.class.to_s})" unless( sleep_time.is_a?(Integer) )

    sleep_time
  end # of def update_sleep }}}

  # Data_mapper_init takes a db type and path and initializes the database in case we want to execute this object directly and have no DB
  #
  # @param [String] db_type Type of the database connector used, eg. sqlite3
  # @param [String] db_path Path of the database, eg. databases/test.sqlite3
  # @param [Boolean] logging Turns DataMapper logging on or off
  def data_mapper_init db_type = @config.db_type, db_path = @config.db_path, logging = @options.debug # {{{
    # DataMapper::Logger.new( $stdout, :debug ) if( logging )

    db_connector = "#{db_type}://#{Dir.pwd}/#{db_path}"

    @log.message :info, "We don't have any DataMapper init info, so we will create a new database at #{db_connector.to_s} (JokeMachine)"
    DataMapper.setup( :default, db_connector )

    # DataMapper.auto_migrate!  # wipe out existing data
    DataMapper.auto_upgrade!    # try to preserve data and insert NULL's if new colums
    DataMapper.finalize
  end # }}}


  # The function 'parse_cmd_arguments' takes a number of arbitrary commandline arguments and parses them into a proper data structure via optparse
  #
  # @param    [Array]         args  Ruby's STDIN.ARGS from commandline
  # @returns  [OpenStruct]          OpenStruct object containing the result of the parsing process
  def parse_cmd_arguments( args ) # {{{

    original_args                           = args.dup
    options                                 = OpenStruct.new

    # Define default options
    options.verbose                         = false
    options.colorize                        = false
    options.process                         = []
    options.sources                         = []
    options.debug                           = false
    options.db_path                         = "data/databases/test.sqlite3"
    options.db_type                         = "sqlite3"
    options.read                            = false
    options.automatic                       = false
    options.interval                        = 3600  # update normally only every hour
    options.rate                            = false
    options.username                        = ""
    options.manual_input                    = false
    options.joke_count                      = false
    options.random_intervals                = false
    options.random_interval_time            = 25

    pristine_options                        = options.dup

    opts                                    = OptionParser.new do |opts|
      opts.banner                           = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

      opts.on("-d", "--db-path PATH", "Use the database which can be found in PATH") do |d|
        options.db_path = d
      end

      opts.on("-t", "--db-type TYPE", "Use the database of class TYPE (e.g. sqlite3)") do |t|
        options.db_type = t
      end

      opts.on("-r", "--read", "Read jokes that are stored in the DB") do |r|
        options.read = r
      end

      opts.on("-r", "--rate", "Rate jokes that are stored in the DB for user account") do |r|
        options.rate = r
      end

      opts.on("-u", "--username OPT", "Use username OPT") do |u|
        options.username = u
      end

      opts.on("-m", "--manual-input", "Input a joke manually to the Database") do |m|
        options.manual_input = m
      end

      opts.on("-j", "--joke-count", "Count how many jokes we have in the Database") do |j|
        options.joke_count = j
      end

      opts.on("-r", "--random-intervals", "Use random intervals when downloading to mask our usage pattern") do |r|
        options.random_intervals = r
      end

      opts.separator ""
      opts.separator "Specific options:"

      # Boolean switch.
      opts.on("-a", "--automatic", "Run automatically every #{options.interval.to_s} seconds unless the --interval option is given") do |a|
        options.automatic = a
      end

      opts.on("-i", "--interval OPT", "Run every OPT seconds (works only with --automatic together)") do |i|
        options.interval = i.to_i
      end

      # Set of arguments
      opts.on("-p", "--process OPT", @configurations, "Process one or more detected configuration (OPT: #{ @configurations.sort.join(', ') })" ) do |d|
        options.process << d
      end

      # Set of arguments
      opts.on("-s", "--sources OPT", @configurations, "Use only these sources for read and rate (OPT: #{ @configurations.sort.join(', ') })" ) do |d|
        options.sources << d
      end

      # Boolean switch.
      opts.on("-v", "--verbose", "Run verbosely") do |v|
        options.verbose = v
      end

      opts.on("-d", "--debug", "Run in debug mode") do |d|
        options.debug = d
      end

      # Boolean switch.
      opts.on("-q", "--quiet", "Run quietly, don't output much") do |v|
        options.verbose = v
      end

      opts.separator ""
      opts.separator "Common options:"

      # Boolean switch.
      opts.on("-c", "--colorize", "Colorizes the output of the script for easier reading") do |c|
        options.colorize = c
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts `git describe --tags`
        exit
      end
    end

    opts.parse!(args)

    # Show opts if we have no cmd arguments
    if( original_args.empty? )
      puts opts
      exit
    end

    options
  end # of parse_cmd_arguments }}}


  # Reads a YAML config describing the joke source to aquire from
  #
  # @param    [String]      filename    String, representing the filename and path to the config file
  # @returns  [OpenStruct]              Returns an openstruct containing the contents of the YAML read config file (uses the feature of Extension.rb)
  def read_config filename # {{{

    # Pre-condition check
    raise ArgumentError, "Filename argument should be of type string, but it is (#{filename.class.to_s})" unless( filename.is_a?(String) )

    # Main
    @log.message :debug, "Loading this config file: #{filename.to_s}"
    result = File.open( filename, "r" ) { |file| YAML.load( file ) }                 # return proc which is in this case a hash
    result = hashes_to_ostruct( result ) 

    # Post-condition check
    raise ArgumentError, "The function should return an OpenStruct, but instead returns a (#{result.class.to_s})" unless( result.is_a?( OpenStruct ) )

    result
  end # }}}


  # This function turns a nested hash into a nested open struct
  #
  # @author Dave Dribin
  # Reference: http://www.dribin.org/dave/blog/archives/2006/11/17/hashes_to_ostruct/
  #
  # @param    [Object]    object    Value can either be of type Hash or Array, if other then it is returned and not changed
  # @returns  [OStruct]             Returns nested open structs
  def hashes_to_ostruct object # {{{

    return case object
    when Hash
      object = object.clone
      object.each { |key, value| object[key] = hashes_to_ostruct(value) }
      OpenStruct.new( object )
    when Array
      object = object.clone
      object.map! { |i| hashes_to_ostruct(i) }
    else
      object
    end

  end # of def hashes_to_ostruct }}}

end # of class JokeMachine }}}


# Direct Invocation
if __FILE__ == $0 # {{{
  options = JokeMachine.new.parse_cmd_arguments( ARGV )
  jm      = JokeMachine.new( options )
end # of if __FILE__ == $0 }}}


