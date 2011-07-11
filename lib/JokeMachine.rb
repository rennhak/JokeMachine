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

# Custom includes (changes object behaviors)
require 'Extensions.rb'
require 'Logger.rb'

# }}}


# The JokeMachine class controls the aquisition and display and rating of jokes.
class JokeMachine

  def initialize options = nil # {{{
    @options = options

    @log     = Logger.new( @options )

    # Minimal configuration
    @config                       = OpenStruct.new
    @config.os                    = "Unknown"
    @config.platform              = "Unknown"
    @config.encoding              = "UTF-8"
    @config.archive_dir           = "archive"
    @config.database_dir          = "database"
    @config.config_dir            = "configurations"
    @config.cache_dir             = "cache"

    # Determine which configs are available
    @configurations       = Dir[ "#{@config.config_dir}/*.yaml" ].collect { |d| d.gsub( "#{@config.config_dir}/", "" ).gsub( ".yaml", "" ) }

    unless( options.nil? )
      @log.message :success, "Starting #{__FILE__} run"
      @log.message :debug,    "Colorizing output as requested" if( @options.colorize )

      ####
      # Main Control Flow
      ##########

      # Reuse if desired
      # use_cache     if( @options.cache )

      unless( @options.process.empty? )
        @options.process.each do |config_file|
          config_filename    = @config.config_dir + "/" + config_file + ".yaml"
          @log.message :info, "Loading config file (#{config_filename})"

          @config                     = read_config( config_filename )
          # @file                     = @config.filename
        end # of @options.process.each
      end # of unless( @options.process.empty? )

    end # of unless( options.nil? )

    @log.message :success, "Finished processing of #{config_filename.to_s}"

  end # of def initalize }}}


  # The function 'parse_cmd_arguments' takes a number of arbitrary commandline arguments and parses them into a proper data structure via optparse
  #
  # @param    [Array]         args  Ruby's STDIN.ARGS from commandline
  # @returns  [OptionParser]        Ruby optparse package options hash object
  def parse_cmd_arguments( args ) # {{{

    options                                 = OpenStruct.new

    # Define default options
    options.verbose                         = false
    options.colorize                        = false
    options.process                         = []

    pristine_options                        = options.dup

    opts                                    = OptionParser.new do |opts|
      opts.banner                           = "Usage: #{__FILE__.to_s} [options]"

      opts.separator ""
      opts.separator "General options:"

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
        exi.sortt
      end
    end

    opts.parse!(args)

    # Show opts if we have no cmd arguments
    if( options == pristine_options )
      puts opts
      puts ""
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



end # of class JokeMachine


# Direct Invocation
if __FILE__ == $0 # {{{
  options = JokeMachine.new.parse_cmd_arguments( ARGV )
  jm      = JokeMachine.new( options )
end # of if __FILE__ == $0 }}}


