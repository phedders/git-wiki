Wiki::Plugin.define 'engine/maruku' do
  require 'maruku'

  Wiki::Mime.add('text/x-maruku', %w(maruku), %w(text/plain)) do |io|
    io.read(8) == '#!maruku'
  end

  Wiki::Engine.create(:maruku, :priority => 2, :layout => true, :cacheable => true) do
    accepts {|page| page.mime == 'text/x-maruku' || page.mime == 'text/x-markdown' }
    filter do |page,content|
      content.sub!(/^#!(maruku|markdown)\s+/,'')
      doc = Maruku.new(content)
      [page, doc.to_html]
    end
  end
end
