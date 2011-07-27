# File: Website.rb

# Meta Class to coordinate polling frequency and other options to access a particular website
class Website
  include DataMapper::Resource

  property :id,               Serial
  property :created_at,       DateTime
  property :last_access,      DateTime

  property :name,             String
end


