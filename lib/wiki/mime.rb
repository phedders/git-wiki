require 'wiki/mime_tables'
require 'wiki/extensions'

module Wiki
  # Mime type detection
  class Mime
    attr_reader :type, :mediatype, :subtype

    # Mime type by type string
    def initialize(type)
      @type      = type
      @mediatype = @type.split('/')[0]
      @subtype   = @type.split('/')[1]
    end

    # Add custom mime type. You have to
    # specify the type, a string list of file extensions,
    # a string list of parent mime types and an optional
    # detector block for magic detection.
    def self.add(type, extensions, parents, &block)
      TYPES[type] = [extensions, parents, block_given? ? proc(&block) : nil]
      extensions.each do |ext|
        EXTENSIONS[ext] = type
      end
    end

    # Returns true if type is a text format
    def text?
      child_of? 'text/plain'
    end

    # Returns true if type is child of parent type
    def child_of?(parent)
      child?(type, parent)
    end

    # Get string list of file extensions
    def extensions
      TYPES.key?(type) ? TYPES[type][0] : []
    end

    # Lookup mime type by file extension
    def self.by_extension(ext)
      mime = EXTENSIONS[ext.downcase]
      mime ? new(mime) : nil
    end

    # Lookup mime type by magic content analysis
    # That could be slow
    def self.by_magic(content)
      io = content.respond_to?(:rewind) ? content : StringIO.new(content.to_s, 'rb')
      mime = TYPES.keys.find do |type|
        io.rewind
        TYPES[type][2] && TYPES[type][2].call(io)
      end
      mime ? new(mime) : nil
    end

    # Return type as string
    def to_s
      type
    end

    # Allow comparison with string
    def ==(x)
      type == x.to_s
    end

    private

    def child?(child, parent)
      return true if child == parent
      TYPES.key?(child) ? TYPES[child][1].any? {|p| child?(p, parent) } : false
    end
  end
end
