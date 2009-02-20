Wiki::Plugin.define 'engine/image' do
  Wiki::Engine.create(:image, :priority => 1, :layout => true) do
    accepts {|page| page.mime.mediatype == 'image' }
    output  {|page| "<img src=\"#{object_path(page, :output => 'raw')}\"/>" }
  end
end
