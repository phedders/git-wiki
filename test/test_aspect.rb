require 'test/unit'
require 'wiki/aspect'

class TC_Aspect < Test::Unit::TestCase

  class SimpleBeforeMachine
    extend Wiki::Aspect
    
    def process(data)
      data + "\nfound"
    end

    before_method :process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    before_method :process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class BeforeSugarMachine
    extend Wiki::Aspect
    
    def process(data)
      data + "\nfound"
    end

    before_process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    before_process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class SimpleAfterMachine
    extend Wiki::Aspect
    
    def process(data)
      data + "\nfound"
    end

    after_method :process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    after_method :process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class AfterSugarMachine
    extend Wiki::Aspect
    
    def process(data)
      data + "\nfound"
    end

    after_process do |data|
      data + "\nmelt"
    end

    def process2(data1, data2)
      [data1 + "\n2", data2 + "\n2"]
    end

    after_process2 do |data1,data2|
      [data1 + "\n1", data2 + "\n1"]
    end
  end

  class SimpleAroundMachine
    extend Wiki::Aspect

    def work(data)
      "work with " + data
    end

    around_method :work do |proc, data|
      proc["before " + data] + " after"
    end

    def work2(data1, data2)
      ["1 " + data1, "2 " + data2]
    end

    around_method :work2 do |proc, data1, data2|
      a, b = proc["before " + data1, "before " + data2]
      [a + " after", b + " after"]
    end
  end

  class AroundSugarMachine
    extend Wiki::Aspect

    def work(data)
      "work with " + data
    end

    around_work do |proc, data|
      proc["before " + data] + " after"
    end

    def work2(data1, data2)
      ["1 " + data1, "2 " + data2]
    end

    around_work2 do |proc, data1, data2|
      a, b = proc["before " + data1, "before " + data2]
      [a + " after", b + " after"]
    end
  end

  class SuperMachine
    extend Wiki::Aspect

    def work(a, b)
      ["#{a}1", "#{b}1"]
    end

    before_work do |a,b|
      ["#{a}2", "#{b}2"]
    end

    after_work do |a,b|
      ["#{a}3", "#{b}3"]
    end

    around_work do |proc, a, b|
      a, b = proc["4#{a}", "4#{b}"]
      ["#{a}5", "#{b}5"]
    end
  end

  class SuperMachine2
    extend Wiki::Aspect

    def work(a, b)
      ["#{a}1", "#{b}1"]
    end

    def work_step2(a, b)
      ["#{a}2", "#{b}2"]
    end

    def work_step3(a, b)
      ["#{a}3", "#{b}3"]
    end

    def work_step4(proc, a, b)
      a, b = proc["4#{a}", "4#{b}"]
      ["#{a}5", "#{b}5"]
    end

    before_work :work_step2
    after_work :work_step3
    around_work :work_step4

    around_work do |proc, a, b|
      a, b = proc["x#{a}", "x#{b}"]
      ["#{a}y", "#{b}y"]
    end
  end

  class SuperMachine3 < SuperMachine2
    around_work do |proc, a, b|
      a, b = proc[".#{a}", ".#{b}"]
      ["#{a},", "#{b},"]
    end

    after_work do |a, b|
      ["#{a}n", "#{b}n"]
    end

    after_work do |a, b|
      ["#{a}j", "#{b}j"]
    end

    before_work do |a, b|
      ["m#{a}", "m#{b}"]
    end

    around_work do |proc,a, b|
      a, b = proc["A#{a}", "A#{b}"]
      ["#{a}E", "#{b}E"]
    end
  end

  def test_before
    machine = SimpleBeforeMachine.new
    assert_equal "metal\nmelt\nfound", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n1\n2", a
    assert_equal "b\n1\n2", b
  end

  def test_sugar_before
    machine = BeforeSugarMachine.new
    assert_equal "metal\nmelt\nfound", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n1\n2", a
    assert_equal "b\n1\n2", b
  end

  def test_after
    machine = SimpleAfterMachine.new
    assert_equal "metal\nfound\nmelt", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n2\n1", a
    assert_equal "b\n2\n1", b
  end

  def test_sugar_after
    machine = AfterSugarMachine.new
    assert_equal "metal\nfound\nmelt", machine.process("metal")
    
    a,b = machine.process2("a", "b")
    assert_equal "a\n2\n1", a
    assert_equal "b\n2\n1", b
  end

  def test_around
    machine = SimpleAroundMachine.new
    assert_equal "work with before ruby after", machine.work('ruby')

    a,b = machine.work2("a", "b")
    assert_equal "1 before a after", a
    assert_equal "2 before b after", b
  end

  def test_sugar_around
    machine = AroundSugarMachine.new
    assert_equal "work with before ruby after", machine.work('ruby')

    a,b = machine.work2("a", "b")
    assert_equal "1 before a after", a
    assert_equal "2 before b after", b
  end

  def test_super
    machine = SuperMachine.new
    a,b = machine.work("a", "b")
    assert_equal "4a2135", a
    assert_equal "4b2135", b
  end

  def test_super2
    machine = SuperMachine2.new
    a,b = machine.work("a", "b")
    assert_equal "4xa2135y", a
    assert_equal "4xb2135y", b
  end

  def test_super3
    machine = SuperMachine3.new
    a,b = machine.work("a", "b")
    assert_equal "4x.mAa2135y,njE", a
    assert_equal "4x.mAb2135y,njE", b
  end
end
