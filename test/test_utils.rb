require 'wiki/extensions'
require 'wiki/utils'

class TC_Utils < Test::Unit::TestCase
  include Wiki::Utils

  def test_blank?
    assert ''.blank?
    assert({}.blank?)
    assert [].blank?
    assert nil.blank?
    assert !'foo'.blank?
    assert !{42=>'answer'}.blank?
    assert ![42].blank?
    assert !42.blank?
  end

  def test_pluralize
    assert_equal '0 tests', 'test'.pluralize(0, 'tests')
    assert_equal '1 test', 'test'.pluralize(1, 'tests')
    assert_equal '3 tests', 'test'.pluralize(3, 'tests')
  end

  def test_last_lines
    assert_equal "long\ntext", "a\nlong\ntext".last_lines(2)
    assert_equal "a\nlong\ntext", "a\nlong\ntext".last_lines(10)
  end

  def test_ends_with?
    assert '123456789'.ends_with?('89')
    assert !'123456789'.ends_with?('98')
  end

  def test_cleanpath
    assert_equal '', '/'.cleanpath
    assert_equal 'a/b', '/a/b/c/../'.cleanpath
    assert_equal 'a/d', '/a/./b/../c/../d/./'.cleanpath
    assert_equal '1/2', '1///2'.cleanpath
    assert_equal '', 'root'.cleanpath
    assert_equal '2', '///root/1/../2'.cleanpath
  end

  def test_urlpath
    assert_equal '/root', '/'.urlpath
    assert_equal '/a/b', '/a/b/c/../'.urlpath
    assert_equal '/a/d', '/a/./b/../c/../d/./'.urlpath
    assert_equal '/1/2', '1///2'.urlpath
    assert_equal '/root', 'root'.urlpath
    assert_equal '/2', '///root/1/../2'.urlpath
  end

  def test_trunacte
    assert_equal 'Annabel Lee...', 'Annabel Lee It was many and many a year ago'.truncate(11)
    assert_equal 'In a kingdom by the sea', 'In a kingdom by the sea'.truncate(39)
  end

  def test_slash
    assert_equal '', ''/''
    assert_equal 'a/b', '//a/b///'/''
    assert_equal 'a/b/c', 'a'/'x'/'..'/'b'/'c'/'.'
  end

  def test_forbid
    assert_raise Wiki::MessageError do
      forbid('Forbidden' => true)
    end
    assert_raise Wiki::MessageError do
      forbid('Allowed'   => false,
             'Forbidden' => true)
    end
  end
end
