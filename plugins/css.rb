module Wiki
  Mime.add('text/x-sass', %w(sass), %w(text/plain))

  Engine.create(:css, 6, false) do
    accepts {|page| page.extension == 'sass' }
    output  {|page| Sass::Engine.new(page.content, :style => :compact).render }
    mime    {|page| 'text/css' }
  end
end
