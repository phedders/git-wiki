require 'test/unit'
require 'wiki/object'

module GitSupport
  def setup
    @repo_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    @repo = Grit::Repo.new(@repo_path)
    page = Wiki::Page.new(@repo, 'Home')
    page.write('This is the main page of the wiki.', 'Initialize Repository')
  end

  def teardown
    FileUtils.rm_rf(@repo_path)
  end
end
