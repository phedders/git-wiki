Wiki::Plugin.define 'engine/textile' do
  require 'redcloth'

  Wiki::Mime.add('text/x-textile', %w(textile), %w(text/plain)) do |io|
    io.read(9) == '#!textile'
  end

  Wiki::Engine.create(:textile, :priority => 1, :layout => true, :cacheable => true) do
    accepts {|page| page.mime == 'text/x-textile' }
    filter do |page,content|
      content.sub!(/^#!textile\s+/,'')
      doc = RedCloth.new(content)
      doc.sanitize_html = true
      [page, doc.to_html]
    end
  end
end
