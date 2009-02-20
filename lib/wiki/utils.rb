require 'wiki/extensions'

def reset_timestamp
  $start_time = Time.now
end

def timestamp
  STDERR.puts caller[0] + " " + (Time.now - $start_time).to_s
end

module Wiki
  class WikiError < StandardError; end

  class MessageError < WikiError; end

  module Utils
    def self.included(base)
      # Also as class methods
      base.extend self
    end

    def escape_html(html)
      CGI::escapeHTML(html.to_s)
    end

    def forbid(conds)
      failed = conds.keys.select {|key| conds[key]}
      raise MessageError.new(failed) if !failed.empty?
    end
  end
end
