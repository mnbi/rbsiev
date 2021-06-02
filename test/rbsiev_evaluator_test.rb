# frozen_string_literal: true

require "test_helper"

class RbsievEvaluatorTest < Minitest::Test
  include RbsievTestUtils

  def setup
    @eva = Rbsiev::Evaluator.new
    @env = Rbsiev.setup_environment
  end

  def test_evaluator_class_has_a_method_to_generate_version_string
    assert Rbsiev::Evaluator.respond_to?(:version)
    ver = Rbsiev::Evaluator.version
    assert_includes ver, "rbsiev.evaluator"
    assert_includes ver, ":version"
    assert_includes ver, Rbsiev::VERSION
    assert_includes ver, ":release"
    assert_includes ver, Rbsiev::RELEASE
  end

  def test_it_can_eval_empty_list
    assert_scm_eval Rbsiev::SCM_EMPTY_LIST, "()"
  end

  def test_it_can_eval_boolean
    ["#t", "#true", ].each {|s| assert_scm_eval true,  s}
    ["#f", "#false",].each {|s| assert_scm_eval false, s}
  end

  def test_it_can_eval_number
    ["0", "123", "-456", "7.8901", "6.78+9.0i"].each { |num|
      result = scm_eval(num)
      assert_equal Kernel.eval(num), result
    }
    ["1/2", "-2/3", "4/5"].each { |rat|
      result = scm_eval(rat)
      rat_parts = rat.split("/").map{|e| Kernel.eval(e)}
      rb_rat = Rational(*rat_parts)
      assert_equal rb_rat, result
    }
  end

  def test_it_can_eval_lambda_expression
    source = "(lambda (n) (+ n 1))"
    result = scm_eval(source)
    assert_kind_of Rbsiev::Procedure, result
    assert_equal ["n"], result.parameters(bare: true)
  end

  def test_it_can_apply_primitive_procedure
    source = "(+ 1 2 3)"
    result = scm_eval(source)
    assert_equal 6, result
  end

  def test_it_can_apply_compond_procedure
    source = "((lambda (n m) (* n m)) 4 5)"
    result = scm_eval(source)
    assert_equal 20, result
  end

  def test_it_can_eval_if
    source = "(if (< -1 0) \"nega\")"
    result = scm_eval(source)
    assert_equal "nega", result
  end

  def test_it_can_eval_if_with_alternate
    source = "(if (< 10 0) \"nega\" \"posi\")"
    result = scm_eval(source)
    assert_equal "posi", result
  end

  def test_it_can_eval_define_variable
    source = "(define foo 7) foo"
    result = scm_eval(source)
    assert_equal 7, result
  end

  def test_it_can_eval_define_procedure
    source = "(define (foo x y) (/ (+ x y) 2.0)) (foo 3 5)"
    result = scm_eval(source)
    assert_equal 4.0, result
  end

  def test_it_can_eval_assignment_varriable
    source = "(define foo 9) (set! foo 11) foo"
    result = scm_eval(source)
    assert_equal 11, result
  end

  def test_it_can_eval_cond
    source = "(cond ((< -1 0) \"nega\") ((= -1 0) \"zero\") (else \"posi\"))"
    result = scm_eval(source)
    assert_equal "nega", result
  end

  def test_it_can_eval_let
    source = "(let ((x 1) (y 2)) (+ x y))"
    result = scm_eval(source)
    assert_equal 3, result
  end

  def test_it_can_eval_named_let
    source = "(let iter ((c 1) (r 1)) (if (< 5 c) r (iter (+ c 1) (* r c))))"
    result = scm_eval(source)
    assert_equal 120, result
  end

  def test_it_can_eval_let_star
    source = "(let* ((x 3) (y (+ x 5))) (* x y))"
    result = scm_eval(source)
    assert_equal (3 * (3 + 5)), result
  end

  def test_it_can_eval_letrec
    source = "(letrec ((fact (lambda (n) (if (= n 0) 1 (* n (fact (- n 1))))))) (fact 6))"
    result = scm_eval(source)
    assert_equal 720, result
  end

  def test_it_can_eval_begin
    source = "(begin (+ 1 2) (+ 3 4) (+ 5 6))"
    result = scm_eval(source)
    assert_equal 11, result
  end

  def test_it_can_eval_do
    source = "(do ((n 1 (+ n 1)) (result 1)) ((> n 10) result) (set! result (* result n)))"
    result = scm_eval(source)
    assert_equal 3628800, result
  end

  private

  def assert_scm_eval(expected, source)
    assert_equal expected, scm_eval(source)
  end

  def scm_eval(source)
    node = scm2ast(source)
    @eva.eval(node, @env)
  end
end
