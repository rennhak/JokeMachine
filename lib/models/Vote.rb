# File: Vote.rb

# Class to handle user votes for specfic jokes
class Vote
  include DataMapper::Resource

  property :id,               Serial
  property :created_at,       DateTime

  property :username,         String

  property :joke_id,          Integer
  property :percent,          Integer
end


