Wiki::Plugin.define 'engine/css' do
  Wiki::Mime.add('text/x-sass', %w(sass), %w(text/plain))

  Wiki::Engine.create(:css, :priority => 6, :layout => false, :cacheable => true) do
    accepts {|page| page.extension == 'sass' }
    output  {|page| Sass::Engine.new(page.content, :style => :compact).render }
    mime    {|page| 'text/css' }
  end
end
