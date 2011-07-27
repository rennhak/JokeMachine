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

require 'models/User.rb'
require 'models/Vote.rb'

# }}}


# The Rate class provids means to judge a jokes and stores it in the profile of the user in the database
class Rate # {{{

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

    # 0 = most dislike  ; 5 = most like
    # This scale may have an statistical bias
    @likert_scale             = [
                                    "Strongly dislike",
                                    "Dislike",
                                    "Neither like nor dislike",
                                    "Like",
                                    "Strongly like"
                                ]

    @phrase_completion_scale  = [
                                    "Definition of not funny",
                                    "Strongly not funny",
                                    "Stupid",
                                    "Not funny at all",
                                    "Not so funny",
                                    "Neutral",
                                    "A little bit funny",
                                    "Rather funny",
                                    "Really funny",
                                    "Hilarious",
                                    "The most funny joke ever",
                                ]

    @percent_scale            = [ 0, 100 ]

  end # of def initialize }}}


  # The function stores rating value for a given joke in the database
  def unrated # {{{

    # answer = ask( "Please rate the joke (0 = totally unfunny, 100 = Hilarious", :percent )

    user = User.first( :username => @username )
    if( user.nil? )
      @log.message :warning, "Couldn't find the user '#{@username}' in the DB, creating a new account"
      user          = User.new
      user.username = @username
      user.save!
    end

    @log.message :debug, "Using user #{user.username.to_s} which has #id #{user.id.to_s} to rate jokes"

    # get rid of jokes that we already rated
    joke_ids = []
    votes     = Vote.all( :username => @username )
    votes.each { |v| joke_ids << v.joke_id }

    @jokes.delete_if do |j|
      joke_ids.include?( j.id )
    end 

    # Only vote on new unvoted jokes
    @log.message :info, "Going to show you #{@jokes.length.to_s} jokes you haven't rated yet"
    @jokes.each_with_index do |joke, index|

      @log.message :info, "Showing you joke ##{index.to_s} of #{@jokes.length.to_s}\n"

      vote            = Vote.new
      vote.joke_id    = joke.id
      vote.username   = @username 

      puts joke.to_s
      puts "\n"
      answer          = ask( "Please rate the joke (0 = totally unfunny, 100 = Hilarious", :percent )
      vote.percent    = answer.to_i
      vote.save!

      system( "clear" )
    end

  end # }}}


  # The function ask will take a simple string query it on the CMD and wait for an answer e.g. "y" (or enter)
  #
  # @param   [String]   question          String, representing the question you want to query.
  # @param   [Array]    allowed_answers   Array, representing the allowed answers
  # @returns [Boolean]                    Boolean, true for yes, false for no
  def get_choice_from_bipolar question, allowed_answers = %w[ y n ] # {{{
    print "#{question.to_s} [#{allowed_answers.join(", ")}] : "
    answer = STDIN.gets.to_s.chop
    return true  if( answer =~ %r{y}i )
    return false if( answer =~ %r{n}i )
  end # of def ask }}}


  # The function get_choice_from_listing asks the user to answer a according to a given listing sequence
  #
  # @param    [String]        question    String, representing the question which the user should be asked together with this listing.
  # @param    [Array]         data        Array, consisting of values, [ value, ... ]
  #
  # @returns  [Integer]                   Integer, representing the choice the user entered
  def get_choice_from_listing question, data # {{{

    selection = nil

    while( selection.nil? )

      print "#{question.to_s} : \n"

      data.each_with_index do |d, i|
        printf( "(%-2i) %s\n", i, d )
      end

      print "\n>> "
      selection                  = ( ( STDIN.gets ).chomp )

    end

    selection
  end # of def get_choice_from_listing }}}


  # The function takes a numerical range argument and asks the user to select from it
  #
  # @param    [String]        question    String, representing the question which the user should be asked together with this listing.
  # @param    [Integer]       from        Integer, representing the start of the numerical range
  # @param    [Integer]       to          Integer, representing the end of the numerical range
  # @returns  [Integer]                   Integer, representing the desired percentage
  def get_choice_from_range question, from = @percent_scale.first, to = @percent_scale.last # {{{
    selection = nil
    finished  = false

    while( not finished )

      print "#{question.to_s} "

      printf( "(%i-%i) : ", from, to )
      STDOUT.flush
      selection                  = ( ( STDIN.gets ).chomp )

      if( selection == "" )
        puts "The selection needs to be of type integer!"
      else
        if( selection.tr( "0-9", "" ) == "" )
          selection = selection.to_i
          if( selection >= from and selection <= to )
            finished = true
          else
            puts "The selection needs to be inside the range from #{from.to_s} to #{to.to_s}!"
          end
        else
          puts "The input can only be of type integer"
        end
      end

    end # of while

    selection
  end # of def get_choice_from_range }}}


  # The ask function takes a question and a type argument of the desired question type (e.g. :likert, :phrase, :percent)
  #
  # @param    [String]        question    String, representing the question which the user should be asked together with this listing.
  # @param    [Symbol]        type        Symbol, one of either: :likert, :phrase, :percent, :bipolar
  def ask question, type # {{{

    allowed = [:bipolar, :likert, :phrase, :percent]
    answer  = nil

    # Pre-condition check # {{{
    raise ArgumentError, "The type (#{type.to_s}) is not among the allowed types (#{allowed.join(", ")})" unless( allowed.include?( type ) )
    raise ArgumentError, "The question needs to be of type string but is (#{question.class.to_s})" unless( question.is_a?(String) )
    # }}}

    # Main
    case type
      when :bipolar
        answer = get_choice_from_bipolar( question )
      when :likert
        answer = get_choice_from_listing( question, @likert_scale )
      when :phrase
        answer = get_choice_from_listing( question, @phrase_completion_scale )
      when :percent
        answer = get_choice_from_range( question )
    end

    # Post condition check

    answer
  end # }}}

end # of class Rate }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

