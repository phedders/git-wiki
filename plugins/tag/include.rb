Wiki::Plugin.define 'tag/include' do
  depends_on 'tag/support'
  load_after 'engine/*'

  Wiki::Engine.enhance :creole, :textile, :markdown do
    define_tag(:include, :requires => :page) do |page,elem|
      attrs = elem.attributes
      if page = Wiki::Page.find(page.repo, attrs['page'])
        engine = Wiki::Engine.find(page)
        if engine.layout?
          engine.render(page)
        else
          "<span class=\"error\">No engine found for #{attrs['page']}</span>"
        end
      else
        "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
      end
    end
  end
end
