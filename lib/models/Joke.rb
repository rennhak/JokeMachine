# File: Joke.rb

class Joke
  include DataMapper::Resource

  property :id,               Serial
  property :created_at,       DateTime

  property :last_modified,    String
  property :charset,          String
  property :content_encoding, String

  property :uri,              String,     :length => 200,     :required => true
  property :sha1sum,          String,     :length => 41
  property :content,          String,     :length => 65536,   :required => true
  property :title,            String,     :length => 500,     :required => true

end


