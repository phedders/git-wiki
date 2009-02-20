Wiki::Plugin.define 'misc/highlight_patch' do
  depends_on 'misc/pygments'

  module Wiki::Helper
    def format_patch(diff)
      Pygments.pygmentize(diff.patch, :format => 'diff', :cache => true, :cache_key => "patch_#{diff.to}_#{diff.from}")
    end
  end
end
