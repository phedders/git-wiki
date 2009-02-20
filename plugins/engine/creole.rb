require 'wiki/mime'

Wiki::Plugin.define 'engine/creole' do
  require 'creole'

  Wiki::Mime.add('text/x-creole', %w(creole text), %w(text/plain)) do |io|
    io.read(8) == '#!creole'
  end

  Wiki::Engine.create(:creole, :priority => 1, :layout => true, :cacheable => true) do
    accepts do |page|
      page.mime == 'text/x-creole'
    end

    filter do |page,content|
      creole = Creole::CreoleParser.new
      class<< creole
        include Wiki::Helper
        def make_local_link(path)
          object_path(@page, :path => path)
        end
        def make_image(path, title)
          args = (title || '').split('|')
          image_path, page_path = path, path
          if !args.delete('raw')
            image_path = object_path(@page, :path => path, :output => :raw)
            page_path = object_path(@page, :path => path)
          end
          image_path = escape_html(image_path)
          page_path = escape_html(page_path)
          nolink = args.delete('nolink')
          box = args.delete('box')
          alt = args[0] ? " alt=\"#{escape_html args[0]}\"" : ''
          if nolink
            "<img src=\"#{image_path}\"#{alt}/>"
          elsif box
            caption = args[0] ? "<span class=\"caption\">#{escape_html args[0]}</span>" : ''
            "<div class=\"img\"><a href=\"#{page_path}\"><img src=\"#{image_path}\"#{alt}/>#{caption}</a></div>"
          else
            "<a href=\"#{page_path}\" class=\"img\"><img src=\"#{image_path}\"#{alt}/></a>"
          end
        end
      end
      creole.instance_variable_set(:@page, page)
      [page, creole.parse(content.sub(/^#!creole\s+/,''))]
    end
  end
end
