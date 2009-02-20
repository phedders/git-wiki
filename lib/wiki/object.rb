require 'sinatra/base'
require 'grit'
require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  PATH_PATTERN = '[\w:.+\-_\/](?:[\w:.+\-_\/ ]*[\w.+\-_\/])?'
  SHA_PATTERN = '[A-Fa-f0-9]{5,40}'
  STRICT_SHA_PATTERN = '[A-Fa-f0-9]{40}'

  # Wiki repository object
  class Object
    include Utils

    # Raised if object is not found in the repository
    class NotFound < Sinatra::NotFound
      def initialize(path)
        super("#{path} not found", path)
      end
    end

    attr_reader :repo, :path, :commit, :object

    # Find object in repo by path and commit sha
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

    # Find object but raise not found exceptions
    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
    end

    # Constructor
    def initialize(repo, path, object = nil, commit = nil, current = false)
      path ||= ''
      path = path.cleanpath
      forbid_invalid_path(path)
      @repo = repo
      @path = path.cleanpath
      @object = object
      @commit = commit
      @current = current
      @prev_commit = @latest_commit = @history = nil
    end

    # Newly created object, not yet in repository
    def new?
      !@object
    end

    # Object sha
    def sha
      new? ? '' : object.id
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    # Latest commit of this object
    def latest_commit
      update_prev_latest_commit
      @latest_commit
    end

    # History of this object. It is truncated
    # to 30 entries.
    def history
      @history ||= @repo.log('HEAD', path)
    end

    # Previous commit this object was changed
    def prev_commit
      update_prev_latest_commit
      @prev_commit
    end

    # Next commit was changed
    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].date <= @commit.date }
      h.last # FIXME. Does not work correctly if history is too short
    end

    # Type shortcuts
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    # Object name
    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    # Pretty formatted object name
    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
    end

    # Safe name
    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    # Diff of this object
    def diff(from, to)
      @repo.diff(from, to).path(path)
    end

    protected

    def update_prev_latest_commit
      if !@latest_commit
        commits = @repo.log(@commit.id, @path, :max_count => 2)
        @prev_commit = commits[1]
        @latest_commit = commits[0]
      end
    end

    static do
      protected

      def forbid_invalid_path(path)
	forbid('Invalid path' => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
      end

    end

  end

  # Page object in repository
  class Page < Object
    attr_writer :content

    def initialize(repo, path, object = nil, commit = nil, current = nil)
      super(repo, path, object, commit, current)
      @content = nil
    end

    # Find page by path and commit sha
    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.page? ? object : nil
    end

    # Page content
    def content
      @content || saved_content
    end

    # Page content that is already saved to the repository
    def saved_content
      @object ? @object.data : nil
    end

    # Check if there is no unsaved content
    def saved?
      !new? && !@content
    end

    # Shortcut: Set content and save
    def write(content, message, author = nil)
      @content = content
      save(message, author)
    end

    # Save changed content (commit)
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

      @content = @prev_commit = @latest_commit = @history = nil
      @commit = history.first
      @object = @path.blank? ? @commit.tree : @commit.tree/@path || raise(NotFound.new(path))
      @current = true
    end

    # Page extension
    def extension
      path =~ /.\.([^.]+)$/
      $1 || ''
    end

    # Detect mime type by extension, by content or use default mime type
    def mime
      @mime ||= Mime.by_extension(extension) || Mime.by_magic(content) || Mime.new(App.config['default_mime'])
    end
  end

  # Tree object in repository
  class Tree < Object
    def initialize(repo, path, object = nil, commit = nil, current = false)
      super(repo, path, object, commit, current)
      @trees = nil
      @pages = nil
    end

    # Find tree by path and optional commit sha
    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.tree? ? object : nil
    end

    # Get child pages
    def pages
      @pages ||= @object.contents.select {|x| x.is_a? Grit::Blob }.map {|x| Page.new(repo, path/x.name, x, commit, current?)}.sort {|a,b| a.name <=> b.name }
    end

    # Get child trees
    def trees
      @trees ||= @object.contents.select {|x| x.is_a? Grit::Tree }.map {|x| Tree.new(repo, path/x.name, x, commit, current?)}.sort {|a,b| a.name <=> b.name }
    end

    # Get all children
    def children
      trees + pages
    end

    # Pretty name
    def pretty_name
      '&radic;&macr; Root'/path
    end

    # Get archive of current tree
    def archive
      @repo.archive_to_file(sha, "#{safe_name}/", "#{safe_name}.tar.gz")   
    end
  end
end
