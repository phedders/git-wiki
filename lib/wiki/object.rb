require 'sinatra/base'
require 'grit'
require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  PATH_PATTERN = '[\w.+\-_\/](?:[\w.+\-_\/ ]*[\w.+\-_\/])?'
  SHA_PATTERN = '[A-Fa-f0-9]{5,40}'

  class Object
    include Utils

    class NotFound < Sinatra::NotFound
      def initialize(path)
        super("#{path} not found", path)
      end
    end

    attr_reader :repo, :path, :commit, :object

    def self.find(repo, path, sha = nil)
      path ||= ''
      path = path.cleanpath
      forbid_invalid_path(path)
      commit = sha ? repo.commit(sha) : repo.log('HEAD', path, :max_count => 1).first
      return nil if !commit
      object = path.blank? ? commit.tree : commit.tree/path
      return nil if !object 
      return Page.new(repo, path, object, commit, !sha) if object.is_a? Grit::Blob
      return Tree.new(repo, path, object, commit, !sha) if object.is_a? Grit::Tree
      nil
    end

    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
    end

    def new?
      !@object
    end

    def sha
      new? ? '' : object.id
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    def last_commit
      update_prev_last_commit
      @last_commit
    end

    def history
      @history ||= @repo.log('HEAD', path)
    end

    def prev_commit
      update_prev_last_commit
      @prev_commit
    end

    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].date <= @commit.date }
      h.last # FIXME. Does not work correctly if history is too short
    end
      
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
    end

    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    def diff(from, to)
      @repo.diff(from, to).path(path)
    end

    def initialize(repo, path, object = nil, commit = nil, current = false)
      path ||= ''
      path = path.cleanpath
      forbid_invalid_path(path)
      @repo = repo
      @path = path.cleanpath
      @object = object
      @commit = commit
      @current = current
      @prev_commit = @last_commit = @history = nil
    end

    protected

    def update_prev_last_commit
      if !@last_commit
        commits = @repo.log(@commit.id, @path, :max_count => 2)
        @prev_commit = commits[1]
        @last_commit = commits[0]
      end
    end

    static do
      protected

      def forbid_invalid_path(path)
	forbid('Invalid path' => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
      end

    end

  end

  class Page < Object
    attr_writer :content

    def initialize(repo, path, object = nil, commit = nil, current = nil)
      super(repo, path, object, commit, current)
      @content = nil
    end

    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.page? ? object : nil
    end

    def content
      @content || saved_content
    end

    def saved_content
      @object ? @object.data : nil
    end

    def saved?
      !new? && !@content
    end

    def write(content, message, author = nil)
      @content = content
      save(message, author)
    end

    def save(message, author = nil)
      return if @content == saved_content

      forbid('No content'   => @content.blank?,
             'Object already exists' => new? && Object.find(@repo, @path))

      Dir.chdir(@repo.working_dir) {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << @content }
      }
      repo.add(@path)
      # FIXME (Avoid direct cmdline access)
      repo.git.commit(:message => message.blank? ? '(Empty commit message)' : message, :author => author)

      @content = @prev_commit = @last_commit = @history = nil
      @commit = history.first
      @object = @path.blank? ? @commit.tree : @commit.tree/@path || raise(NotFound.new(path))
      @current = true
    end

    def extension
      path =~ /.\.([^.]+)$/
      $1 || ''
    end

    def mime
      @mime ||= Mime.by_extension(extension) || Mime.by_magic(content) || Mime.new(App.config['default_mime'])
    end
  end
  
  class Tree < Object
    def initialize(repo, path, object = nil, commit = nil, current = false)
      super(repo, path, object, commit, current)
      @children = nil
    end
    
    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.tree? ? object : nil
    end

    def children
      @children ||=\
      begin
        @object.contents.select {|x| x.is_a? Grit::Tree }.map {|x| Tree.new(repo, path/x.name, x, commit, current?)}.sort {|a,b| a.name <=> b.name } +
        @object.contents.select {|x| x.is_a? Grit::Blob }.map {|x| Page.new(repo, path/x.name, x, commit, current?)}.sort {|a,b| a.name <=> b.name }
      end                    
    end

    def pretty_name
      '&radic;&macr; Root'/path
    end

    def archive
      @repo.archive_to_file(sha, "#{safe_name}/", "#{safe_name}.tar.gz")   
    end
  end
end
