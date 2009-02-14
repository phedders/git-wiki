require 'sinatra/base'
require 'git'
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
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first rescue nil
      return nil if !commit
      object = git_find(repo, path, commit)
      return nil if !object 
      return Page.new(repo, path, object, commit, !sha) if object.blob?
      return Tree.new(repo, path, object, commit, !sha) if object.tree?
      nil
    end

    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
    end

    def new?
      !@object
    end

    def sha
      new? ? '' : object.sha
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
      @history ||= @repo.log.path(path).to_a
    end

    def prev_commit
      update_prev_last_commit
      @prev_commit
    end

    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].committer_date <= @commit.committer_date }
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
        commits = @repo.log(2).object(@commit.sha).path(@path).to_a
        @prev_commit = commits[1]
        @last_commit = commits[0]
      end
    end

    static do
      protected

      def forbid_invalid_path(path)
	forbid('Invalid path' => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
      end

      def git_find(repo, path, commit)
        return nil if !commit
        if path.blank?
          return commit.gtree rescue nil
        elsif path =~ /\//
          return path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
        else
          return commit.gtree.children[path] rescue nil
        end
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
      @object ? @object.contents : nil
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

      repo.chdir {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << @content }
      }
      repo.add(@path)
      repo.commit(message.blank? ? '(Empty commit message)' : message, :author => author)

      @content = @prev_commit = @last_commit = @history = nil
      @commit = history.first
      @object = git_find(@repo, @path, @commit) || raise(NotFound.new(path))
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
      @children ||= @object.trees.to_a.map {|x| Tree.new(repo, path/x[0], x[1], commit, current?)}.sort {|a,b| a.name <=> b.name } +
                    @object.blobs.to_a.map {|x| Page.new(repo, path/x[0], x[1], commit, current?)}.sort {|a,b| a.name <=> b.name }
    end

    def pretty_name
      '&radic;&macr; Root'/path
    end

    def archive
      @repo.archive(sha, nil, :format => 'tgz', :prefix => "#{safe_name}/")
    end
  end
end
