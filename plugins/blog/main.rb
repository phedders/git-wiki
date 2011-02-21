description    'Blog aspect'
dependencies   'tags', 'utils/assets', 'utils/xml'
export_scripts '*.css'

Page.attributes do
  list(:tags)
end

Application.get '(/:path)/:year(/:month)', :year => '20\d{2}', :month => '(?:0[1-9])|(?:1[0-2])' do
  reroute :get, "/#{params[:path]}", :year => params[:year], :month => params[:month], :aspect => 'blog'
end

Tags::Tag.define 'menu', :optional => :path, :description => 'Show blog menu', :dynamic => true do |context, attrs, content|
  page = Page.find(attrs[:path]) rescue nil
  if page
    Cache.cache("blog-#{page.path}-#{page.version.cache_id}", :update => context.request.no_cache?, :defer => true) do
      years = {}
      page.children.each do |child|
        (years[child.version.date.year] ||= [])[child.version.date.month] = true
      end
      render :menu, :locals => {:years => years, :page => page}
    end
  end
end

Aspects::Aspect.create(:blog, :priority => 3, :layout => true, :cacheable => true, :hidden => true) do
  def accepts?(page); !page.children.empty?; end
  def call(context, page)
    @page = page
    articles = page.children.sort_by {|child| -child.version.date.to_i }

    year = context.params[:year].to_i
    articles.reject! {|article| article.version.date.year != year } if year != 0
    month = context.params[:month].to_i
    articles.reject! {|article| article.version.date.month != month } if month != 0

    @page_nr = [context.params[:page].to_i, 1].max
    per_page = 10
    @page_count = articles.size / per_page + 1
    articles = articles[((@page_nr - 1) * per_page) ... (@page_nr * per_page)].to_a

    @articles = articles.map do |page|
      begin
        subctx = context.subcontext(:page => page, :params => {:included => true})
        content = Aspect.find!(page, :layout => true).call(subctx, page)
        if !context.params[:full]
          paragraphs = XML::Fragment(content).xpath('p')
          content = ''
          paragraphs.each do |p|
            content += p.to_xhtml
            break if content.length > 10000
          end
        end
      rescue Aspect::NotAvailable => ex
        %{<span class="error">#{escape_html ex.message}</span>}
      end
      [page, content]
    end
    render :blog, :locals => {:full => context.params[:full]}
  end
end

__END__
@@ blog.slim
<<<<<<< HEAD:plugins/blog/main.rb
- if @articles.empty?
  .error= :no_articles.t
- else
  .blog
    - @articles.each do |page, content|
      .article
        h2
          a.name href=absolute_path(page) = page.name
        .date= date page.version.date
        .author= :written_by.t(:author => page.version.author.name)
        .content== content
        - if !full
          a.full href=absolute_path(page.path) = :full_article.t
= pagination(page_path(@page), @page_count, @page_nr, :aspect => 'blog')
=======
.blog
  - @articles.each do |page, content|
    .article
      h2
        a.name href=absolute_path(page) = page.name
      .date= date page.version.date
      .author= :written_by.t(:author => page.version.author.name)
      - tags = page.attributes['tags'].to_a
      - if !tags.empty?
        ul.tags
          - tags.each do |tag|
            li= tag
      .content== content
      - if !full
        a.full href=absolute_path(page.path) = :full_article.t
= pagination(page_path(@page), @page_count, @page_nr, :output => 'blog')
>>>>>>> parent of 51e20b1... remove blog tags:plugins/blog/blog.rb
@@ menu.slim
table.blog-menu
  - years.keys.sort.each do |year|
    tr
      td
        a href=absolute_path(page.path/year) = year
      td
        - (1..12).select {|m| years[year][m] }.each do |month|
          - m = '%02d' % month
          a href=absolute_path(page.path/year/m) = m
