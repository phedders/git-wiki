Wiki::Plugin.define 'engine/download' do
  Wiki::Engine.create(:download, :priority => 4, :layout => true) do
    accepts {|page| true }
    output  {|page| "<a href=\"#{object_path(page, :output => 'raw')}\">Download</a>" }
  end
end
