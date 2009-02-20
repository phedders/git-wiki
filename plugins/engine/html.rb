Wiki::Plugin.define 'engine/html' do
  Wiki::Engine.create(:html, :priority => 3, :layout => true, :cacheable => true) do
    accepts {|page| page.mime.text? }
    output  {|page| "<pre>#{escape_html page.content}</pre>" }
    mime    {|page| page.mime }
  end
end
