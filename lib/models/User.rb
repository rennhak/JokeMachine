# File: User.rb

# Class to handle user accounts
class User
  include DataMapper::Resource

  property :id,               Serial
  property :created_at,       DateTime

  property :username,         String

  property :first_name,       String
  property :middle_name,      String
  property :last_name,        String
end


