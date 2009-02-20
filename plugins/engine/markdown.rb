Wiki::Plugin.define 'engine/markdown' do
  require 'rdiscount'

  Wiki::Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain)) do |io|
    io.read(10) == '#!markdown'
  end

  Wiki::Engine.create(:markdown, :priority => 1, :layout => true, :cacheable => true) do
    accepts {|page| page.mime == 'text/x-markdown' }
    filter do |page,content|
      content.sub!(/^#!markdown\s+/,'')
      [page, RDiscount.new(content).to_html]
    end
  end
end
