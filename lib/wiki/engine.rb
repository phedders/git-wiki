require 'wiki/mime'
require 'wiki/extensions'
require 'wiki/aspect'
require 'wiki/utils'

module Wiki
  # An Engine renders pages
  class Engine
    include Helper
    extend Aspect

    # Error which is raised if no appropiate engine is found
    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end

    @engines = {}
    @engine_instances = nil

    # Enhance existing engine classes. This is sugar
    # for class inheritance. The existing
    # engine is replaced with the enhanced version.
    def self.enhance(*names, &block)
      names.each do |name|
        name = name.to_s
        if @engines.key?(name)
          @engines[name] = Class.new(@engines[name], &block)
        end
      end
      @engine_instances = nil
    end

    # Create engine class. This is sugar to create and
    # register an engine class in one step.
    def self.create(name, opts = {}, &block)
      name = name.to_s
      raise ArgumentError.new("Engine #{name} already exists") if @engines.key?(name)
      layout = opts[:layout] || false
      cacheable = opts[:cacheable] || false
      priority = opts[:priority] || 0
      @engines[name] = engine = Class.new(Engine)
      engine.class_eval %{
        def name; "#{name}"; end
        def layout?; #{layout}; end
        def cacheable?; #{cacheable}; end
        def priority; #{priority}; end
      }
      engine.class_eval(&block)
      engine
    end

    # Find appropiate engine for page. An optional
    # name can be given to claim a specific engine.
    def self.find(page, name = nil)
      name = name.to_s

      engine = if name.blank?
        engine_instances.values.sort {|a,b| a.priority <=> b.priority }.find { |e| e.accepts? page }
      else
        e = engine_instances[name]
        e && e.accepts?(page) ? e : nil
      end

      return engine.dup if engine
      raise NotAvailable.new(name)
    end

    def self.engine_instances
      @engine_instances ||= @engines.map_to_hash {|name,klass| [name, klass.new] }
    end

    # Sugar to generate methods
    def self.output(&block);  define_method :output, &block;   end
    def self.filter(&block);  define_method :filter, &block;   end
    def self.mime(&block);    define_method :mime, &block;     end
    def self.accepts(&block); define_method :accepts?, &block; end

    # Acceptor should return true if page would be accepted by this engine
    accepts {|page| false }

    # Render page content (internally)
    output {|page| filter(page, page.content.dup).last }

    # Filter page content
    filter {|page,content| [page, content] }

    # Get output mime type
    mime {|page| 'text/plain' }

    # Render page with caching. This is
    # the primary engine interface
    def render(page)
      Cache.cache('engine', name + page.sha, :disable => !page.saved? || !cacheable?) { output page }
    end

    private_class_method :engine_instances
  end
end
