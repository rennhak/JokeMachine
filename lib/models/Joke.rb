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


  # Display joke properly on STDOUT
  def to_s # {{{
    c = wrap( self.content.to_s.chomp )
    t = wrap( self.title.to_s.chomp )

<<EOS
|^\___________________ [ #{self.source.to_s } ] _________________________________/^|

\t'#{t}'

\t#{c}

|/^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\|

EOS
  end # of def to_s }}}

  # Inspired by: http://www.justskins.com/forums/line-wrapping-66819.html
  # credit: Warren Brown
  def wrap(s)
    s.split("\n").map do |t|
      if t =~ /^[>|]/
        t + "\n"
      else
        t.gsub(/(.{1,74})(\s+|$)/,"\\1\n")
      end
    end.join('')
  end

end


