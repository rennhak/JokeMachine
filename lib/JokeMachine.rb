#!/usr/bin/ruby
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

# Standard includes
require 'rubygems'

# Require DataMapper
require 'rubygems'
require 'datamapper'
require 'dm-core'
require 'dm-migrations'

# Custom includes (changes object behaviors)
require 'Extensions.rb'
require 'Logger.rb'
require 'Display.rb'

# Require custom Joke ADT for searching
require 'models/Joke.rb'

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
      @log.message :debug,    "Colorizing output as requested" if( @options.colorize )

      ####
      # Main Control Flow
      ##########

      # DataMapper
      @config.db_path, @config.db_type = @options.db_path, @options.db_type
      @config.db_connector = "#{@options.db_type}://#{Dir.pwd}/#{@options.db_path}"
      @log.message :info, "Setting up DataMapper (#{@config.db_connector.to_s})"
      data_mapper_init

      unless( @options.process.empty? )
        @options.process.each do |config_file|
          config_filename    = @config.config_dir + "/" + config_file + ".yaml"
          @log.message :info, "Loading config file (#{config_filename})"

          @config                     = read_config( config_filename )

          # Require module
          require "modules/#{@config.module.to_s}/Main.rb"

          # Create instance and get new data
          instance                    = eval( "#{@config.module.capitalize.to_s}.new( @log, @config, @config.db_type, @config.db_path )" )
          amount                      = @config.download_amount
          instance.update!( amount )

          @log.message :success, "Finished processing of #{config_filename.to_s}"
        end # of @options.process.each
      end # of unless( @options.process.empty? )

      # This should maybe be in a client app instead
      if( @options.read )
        @jokes    = ( Joke.all ).reverse
        @display  = Display.new( @jokes )
        @display.to_stdout
      end

    end # of unless( options.nil? )

  end # of def initalize }}}


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
    options.debug                           = false
    options.db_path                         = "data/databases/test.sqlite3"
    options.db_type                         = "sqlite3"
    options.read                            = false

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

      opts.separator ""
      opts.separator "Specific options:"

      # Set of arguments
      opts.on("-p", "--process OPT", @configurations, "Process one or more detected configuration (OPT: #{ @configurations.sort.join(', ') })" ) do |d|
        options.process << d
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
        puts OptionParser::Version.join('.')
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
    result = File.open( filename, "r" ) { |file| YAML.load( file ) }                 # return proc which is in this case a hash

    # Post-condition check
    raise ArgumentError, "The function should return an OpenStruct, but instead returns a (#{result.class.to_s})" unless( result.is_a?( OpenStruct ) )

    result
  end # }}}

end # of class JokeMachine }}}


# Direct Invocation
if __FILE__ == $0 # {{{
  options = JokeMachine.new.parse_cmd_arguments( ARGV )
  jm      = JokeMachine.new( options )
end # of if __FILE__ == $0 }}}


