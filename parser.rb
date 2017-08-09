require 'feedjira'

# Parser class
class ParseRss
  def initialize url
    @feed = Feedjira::Feed.fetch_and_parse url
  rescue Feedjira::NoParserAvailable => e
    raise ParseError, e
  end

  def entries
    feed&.entries
  end

  private
  attr_reader :feed
end

# Exclude a word "NewsPicks"
# => means remove the word "NewsPicks" from each entries??
class EntryConverter
  REGEX = /NewsPicks/
  def initialize entry
    @entry = entry
  end

  def call
    entry&.title.to_s.gsub!(REGEX, "")
    entry&.summary.to_s.gsub!(REGEX, "")
    entry
  end

  private
  attr_reader :entry
end

class EntryOutputter
  def initialize entry
    @entry = entry
  end

  # print entry title to standard output
  def call
    puts entry&.title
  end

  private
  attr_reader :entry
end

class RssParserFacade
  def initialize urls = []
    @urls = urls.select{|url| valid_url? url}
  end

  def run
    urls.each do |url|
      begin
        entryies = ParseRss.new(url).entries
      rescue ParseError => message
        STDERR.print "#{message} for url: #{url}"
        next
      end
      entryies.map{|entry| EntryConverter.new(entry).call}
        .each{|entry| EntryOutputter.new(entry).call}
    end
  end

  private
  attr_reader :urls

  def valid_url? url
    regex = Regexp.new("^#{URI.regexp(%w(http https))}$")
    !(regex =~ url).nil?
  end
end

RssParserFacade.new(ARGV).run
