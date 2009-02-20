Wiki::Plugin.define 'misc/rubypants' do
  require 'rubypants'
  load_after 'engine/*'

  Wiki::Engine.enhance :creole, :markdown, :textile do
    after_filter do |page, content|
      [page, RubyPants.new(content).to_html]
    end
  end
end
