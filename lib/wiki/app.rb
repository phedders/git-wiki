%w(rubygems sinatra/base sinatra/complex_patterns grit haml
sass logger cgi wiki/extensions wiki/utils
wiki/object wiki/helper wiki/user wiki/engine wiki/highlighter wiki/cache).each { |dep| require dep }

module Wiki
  class App < Sinatra::Base
    include Sinatra::ComplexPatterns
    include Helper
    include Utils

    pattern :path, PATH_PATTERN
    pattern :sha,  SHA_PATTERN

    set :haml, :format => :xhtml, :attr_wrapper  => '"'
    set :methodoverride, true
    set :static, true
    set :root, File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    set :raise_errors, false
    set :dump_errors, true

    def initialize
      %w(title repository workspace store cache loglevel logfile default_mime main_page).each do |key|
        raise RuntimeError.new('Application not properly configured') if App.config[key].blank?
      end

      FileUtils.mkdir_p File.dirname(App.config['store']), :mode => 0755
      FileUtils.mkdir_p File.dirname(App.config['logfile']), :mode => 0755
      FileUtils.mkdir_p App.config['cache'], :mode => 0755

      Entry.store = App.config['store']
      Cache.instance = Cache::Disk.new(App.config['cache'])
     
      @logger = Logger.new(App.config['logfile'])
      @logger.level = Logger.const_get(App.config['loglevel'])

      Grit.debug = true
      Grit.logger = @logger
      @repo = Grit::Repo.new(App.config['repository'], :is_bare => true)
      @repo.working_dir = App.config['workspace']

      if !Page.find(@repo, App.config['main_page'])
        page = Page.new(@repo, App.config['main_page'])
        page.write('This is the main page of the wiki.', 'Initialize Repository')
        @logger.info 'Repository initialized'
      end
   end

    before do
      @logger.debug request.env

      # Sinatra does not unescape before pattern matching
      # Paths with spaces won't be recognized
      # FIXME: Implement this as middleware?
      request.path_info = CGI::unescape(request.path_info)

      content_type 'application/xhtml+xml', :charset => 'utf-8'

      forbid('No ip given' => !request.ip)
      @user = session[:user] || User.anonymous(request.ip)
      @footer = nil
      @feed = nil
      @title = ''
    end

    not_found do
      @error = request.env['sinatra.error']
      haml :error
    end

    error do
      @error = request.env['sinatra.error']
      @logger.error @error
      haml :error
    end

    get '/' do
      redirect App.config['main_page'].urlpath
    end

    get '/login', '/signup' do
      haml :login
    end

    post '/login' do
      begin
        session[:user] = User.authenticate(params[:user], params[:password])
        redirect '/'
      rescue MessageError => error
        message :error, error.message
        haml :login
      end
    end

    post '/signup' do
      begin
        session[:user] = User.create(params[:user], params[:password],
                                     params[:confirm], params[:email])
        redirect '/'
      rescue MessageError => error
        message :error, error.message
        haml :login
      end
    end

    get '/logout' do
      session[:user] = @user = nil
      redirect '/'
    end

    get '/profile' do
      haml :profile
    end

    post '/profile' do
      if !@user.anonymous?
        begin
          @user.transaction do |user|
            user.change_password(params[:oldpassword], params[:password], params[:confirm]) if !params[:password].blank?
            user.email = params[:email]
          end
          message :info, 'Changes saved'
          session[:user] = @user
        rescue MessageError => error
          message :error, error.message
        end
      end
      haml :profile
    end

    get '/search' do
      # TODO
      matches = @repo.grep(params[:pattern], nil, :ignore_case => true)
      @matches = []
      matches.each_pair do |id,lines|
        if id =~ /^#{SHA_PATTERN}:(.+)$/
          @matches << [$1,lines.map {|x| x[1] }.join("\n").truncate(100)]
        end
      end
      haml :search
    end

    get '/style.css' do
      begin
        # Try to use wiki version
        params[:output] = 'css'
        params[:path] = 'style.sass'
        show
      rescue Object::NotFound
        last_modified(File.mtime(template_path(:sass, :style)))
        # Fallback to default style
        content_type 'text/css', :charset => 'utf-8'
        sass :style, :sass => {:style => :compact}
      end
    end
    
    get '/archive', '/:path/archive' do
      @tree = Tree.find!(@repo, params[:path])
      content_type 'application/x-tar-gz'
      attachment "#{@tree.safe_name}.tar.gz"
      archive = @tree.archive
      begin
        # See send_file
        response['Content-Length'] ||= File.stat(archive).size.to_s
        halt StaticFile.open(archive, 'rb')
      rescue Errno::ENOENT
        not_found
      end
    end

    get '/history', '/:path/history' do
      @object = Object.find!(@repo, params[:path])
      haml :history
    end

    get '/changelog.rss', '/:path/changelog.rss' do
      object = Object.find!(@repo, params[:path])
      cache_control(object, 'changelog')

      require 'rss/maker'
      content_type 'application/rss+xml', :charset => 'utf-8'
      content = RSS::Maker.make('2.0') do |rss|
        rss.channel.title = App.config['title']
        rss.channel.link = request.scheme + '://' +  (request.host + ':' + request.port.to_s)
        rss.channel.description = App.config['title'] + ' Changelog'
        rss.items.do_sort = true
        object.history.each do |commit|
          i = rss.items.new_item
          i.title = commit.message
          i.link = request.scheme + '://' + (request.host + ':' + request.port.to_s)/object.path/commit.sha
          i.date = commit.committer.date
        end
      end
      content.to_s
    end

    get '/diff', '/:path/diff' do
      @object = Object.find!(@repo, params[:path])
      @diff = @object.diff(params[:from], params[:to])
      haml :diff
    end

    get '/:path/edit', '/:path/append', '/:path/upload' do
      begin
        @page = Page.find!(@repo, params[:path])
        haml :edit
      rescue Object::NotFound
        pass if action? :upload # Pass to next handler because /upload is used twice
        raise
      end
    end

    get '/new', '/upload', '/:path/new', '/:path/upload' do
      begin
        @page = Page.new(@repo, params[:path])
        boilerplate @page
      rescue MessageError => error
        message :new, error.message
      end        
      haml :new
    end

    get '/:sha', '/:path/:sha', '/:path' do
      begin
        show
      rescue Object::NotFound
        params[:path] ||= ''
        redirect(params[:sha] ? params[:path].urlpath : (params[:path]/'new').urlpath)
      end
    end

    put '/:path' do
      @page = Page.find!(@repo, params[:path])
      begin
        if action?(:upload) && params[:file]
          @page.write(params[:file][:tempfile].read, 'File uploaded', @user.author)
          show(@page)
        else
          if action?(:append) && params[:appendix] && @page.mime.text?
            @page.content = @page.content + "\n" + params[:appendix]
          elsif action?(:edit) && params[:content]
            @page.content = params[:content]
          else
            redirect @page.path.urlpath/'edit'
          end

          if params[:preview]
            engine = Engine.find(@page)
            @preview_content = engine.output(@page) if engine.layout?
            haml :edit
          else
            @page.save(params[:message], @user.author)
            show(@page)
          end
        end
      rescue MessageError => error
        message :error, error.message
        haml :edit
      end
    end

    post '/', '/:path' do
      begin
        @page = Page.new(@repo, params[:path])
        if action?(:upload) && params[:file]
          @page.write(params[:file][:tempfile].read, 'File uploaded', @user.author)
          redirect params[:path].urlpath
        elsif action?(:new)
          @page.content = params[:content]
          if params[:preview]
            engine = Engine.find(@page)
            @preview_content = engine.output(@page) if engine.layout?
            haml :new
          else
            @page.save(params[:message], @user.author)
            redirect params[:path].urlpath
          end
        else
          redirect '/new'
        end
      rescue MessageError => error
        message :error, error.message
        haml :new
      end
    end

    private

    def cache_control(object, tag)
      if App.production?
        response['Cache-Control'] = 'private, must-revalidate, max-age=0'
        etag(object.sha + tag)
        last_modified(object.commit.date)
      end
    end

    def show(object = nil)
      object = Object.find!(@repo, params[:path], params[:sha]) if !object || object.new?
      cache_control(object, 'show')

      if object.tree?
        @tree = object
        haml :tree
      else
        @page = object
        engine = Engine.find(@page, params[:output])
        @content = engine.output(@page)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@page).to_s
          @content
        end
      end
    end

    def boilerplate(page)
      if page.path == 'style.sass'
        page.content = lookup_template :sass, :style
      end
    end

  end
end

Wiki::App.safe_require_all(File.join(Wiki::App.root, 'plugins'))
