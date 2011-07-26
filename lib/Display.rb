#!/usr/bin/ruby
#


###
#
# File: Display.rb
#
######


###
#
# (c) 2011, Copyright, Bjoern Rennhak
#
# @file       Display.rb
# @author     Bjoern Rennhak
#
#######


# Libraries {{{

# Custom includes (changes object behaviors)
require 'Extensions.rb'
require 'Logger.rb'

# }}}


# The Display class controls the display of the database content
class Display # {{{

  # Constructor
  #
  # @param  [DataMapper::Collection]    jokes     Requires an instantiated output object of type DataMapper::Collection, e.g. "Joke.all"
  def initialize jokes = nil # {{{
    raise ArgumentError, "Cannot display jokes, have no joke object" if( jokes.nil? )

    @jokes = jokes
  end # of def initialize }}}


  # The function to_stdout prints the jokes to the STDOUT terminal so that it can be read
  #
  # @param  [Integer]                   amount    Requires an integer to determine how many jokes will be displayed on CLI
  # @param  [DataMapper::Collection]    jokes     Requires an instantiated output object of type DataMapper::Collection, e.g. "Joke.all"
  def to_stdout amount = 3, jokes = @jokes # {{{
    puts "-----[ DISPLAYING #{@jokes.length.to_s} JOKES ]----- \n\n"

    @jokes.each_with_index do |joke, index|

      if( ( ( index % amount ) == 0 ) and (index != 0 )) 

        puts "----- [ JOKE NR. #{( index + 1 ).to_s} ] ------"
        puts joke.to_s

        # Pause unstil the user presses a key
        puts "\n[ PRESS A ENTER TO CONTINUE (Index: #{(index + 1 ).to_s} \-> ]"
        STDIN.gets
        system( "clear" )
      else
          puts "----- [ JOKE NR. #{( index + 1 ).to_s} ] ------"
          puts joke.to_s
      end # of if( ( index % listing_amount ) == 0 )

    end
  end # of }}}

end # of class Display }}}


# Direct Invocation
if __FILE__ == $0 # {{{
end # of if __FILE__ == $0 }}}

