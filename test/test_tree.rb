require 'git_support'

class TC_Tree < Test::Unit::TestCase
  include GitSupport

  def page(name)
    p = Wiki::Page.new(@repo, name)
    p.write('content', 'message', 'Author <author@localhorst>')
  end

  def test_commit_browsing
    page('page1')
    page('page2')
    page('page3')

    tree = Wiki::Tree.find!(@repo, '/')
    assert tree.current?
    
    assert_equal tree.children[0].commit.sha, tree.commit.sha
    assert_equal tree.children[1].commit.sha, tree.commit.sha
    assert_equal tree.children[2].commit.sha, tree.commit.sha
    assert tree.children[0].current?
    assert tree.children[1].current?
    assert tree.children[2].current?

    old_tree = Wiki::Tree.find(@repo, '/', tree.prev_commit)
    assert !old_tree.current?
    assert_equal old_tree.commit.sha, tree.prev_commit.sha
    assert_equal old_tree.children[0].commit.sha, old_tree.commit.sha
    assert_equal old_tree.children[1].commit.sha, old_tree.commit.sha
    assert_equal old_tree.children[2].commit.sha, old_tree.commit.sha
    assert !old_tree.children[0].current?
    assert !old_tree.children[1].current?
    assert !old_tree.children[2].current?
  end

  def test_children
    page('page1')
    page('page2')
    page('page3')
    page('tree1/subpage1')
    page('tree1/subpage2')
    page('tree1/subpage3')
    page('tree2/subpage1')
    page('tree2/subpage2')
    page('tree2/subpage3')
    page('tree3/subpage1')
    page('tree3/subpage2')
    page('tree3/subpage3')
    page('tree1/subtree1/subsubpage1')
    page('tree1/subtree1/subsubpage2')
    page('tree1/subtree1/subsubpage3')

    tree = Wiki::Tree.find!(@repo, '/')
    assert_equal 7, tree.children.size
    assert_equal 'tree1', tree.children[0].path
    assert_equal 'tree2', tree.children[1].path
    assert_equal 'tree3', tree.children[2].path
    assert_equal 'Home',  tree.children[3].path
    assert_equal 'page1', tree.children[4].path
    assert_equal 'page2', tree.children[5].path
    assert_equal 'page3', tree.children[6].path

    assert tree.children[0].tree?
    assert tree.children[1].tree?
    assert tree.children[2].tree?
    assert tree.children[3].page?
    assert tree.children[4].page?
    assert tree.children[5].page?
    assert tree.children[6].page?

    tree = Wiki::Tree.find!(@repo, '/tree1')
    assert_equal 4, tree.children.size
    assert_equal 'tree1/subtree1', tree.children[0].path
    assert_equal 'tree1/subpage1', tree.children[1].path
    assert_equal 'tree1/subpage2', tree.children[2].path
    assert_equal 'tree1/subpage3', tree.children[3].path

    assert tree.children[0].tree?
    assert tree.children[1].page?
    assert tree.children[2].page?
    assert tree.children[3].page?
    
    tree = Wiki::Tree.find!(@repo, '/tree1/subtree1')
    assert_equal 3, tree.children.size
    assert_equal 'tree1/subtree1/subsubpage1', tree.children[0].path
    assert_equal 'tree1/subtree1/subsubpage2', tree.children[1].path
    assert_equal 'tree1/subtree1/subsubpage3', tree.children[2].path    

    assert tree.children[0].page?
    assert tree.children[1].page?
    assert tree.children[2].page?
  end
end
