# File: Joke.rb

class Joke
  include DataMapper::Resource

  property :id,               Serial
  property :created_at,       DateTime
  property :downloaded_at,    DateTime

  property :last_modified,    String
  property :charset,          String
  property :content_encoding, String
  property :content_type,     String

  property :joke_id,          String

  property :sha1sum,          String,     :length => 41
  property :title,            String,     :length => 500,     :required => true
  property :content,          String,     :length => 65536,   :required => true

  property :source,           String

  property :ups,              Integer
  property :downs,            Integer

  property :over_18,          Boolean
  property :author,           String
  property :url,              String,     :length => 200,     :required => true

  property :content_sha1sum,  String,     :length => 41
  property :title_sha1sum,    String,     :length => 41
end


