# frozen_string_literal: true

module Rbsiev
  class Evaluator
    include Rubasteme::AST::Misc

    def self.version
      "(rbsiev.evaluator :version #{VERSION} :release #{RELEASE})"
    end

    def initialize
      @verbose = false
    end

    attr_accessor :verbose

    def eval(ast_node, env)
      case ast_node.type
      when :ast_program
        result = nil
        ast_node.each { |node|
          result = self.eval(node, env)
        }
        result
      when :ast_empty_list
        SCM_EMPTY_LIST
      when :ast_boolean
        eval_boolean(ast_node, env)
      when *EV_SELF_EVALUATING
        eval_self_evaluating(ast_node, env)
      when *EV_VARIABLE
        env.lookup_variable_value(identifier(ast_node))
      when *EV_QUOTED
        text_of_quotation(ast_node)
      when *EV_ASSIGNMENT
        eval_assignment(ast_node, env)
      when *EV_DEFINITION
        eval_definition(ast_node, env)
      when *EV_IF
        eval_if(ast_node, env)
      when *EV_LAMBDA
        parameters = ast_node.formals
        body = ast_node.body
        make_procedure(parameters, body, env)
      when *EV_BEGIN
        eval_sequence(begin_action(ast_node), env)
      when *EV_COND
        eval_if(cond_to_if(ast_node), env)
      when :ast_let
        eval_let(ast_node, env)
      when :ast_let_star
        nested_lets = let_star_to_nested_lets(ast_node.bindings,
                                              ast_node.body)
        self.eval(nested_lets, env)
      when *EV_APPLICATION
        apply(self.eval(ast_node.operator, env),
              list_of_values(ast_node.operands, env))
      else
        raise Error, "Unknown expression type -- EVAL: got=%s" % ast_node.type
      end
    end

    def apply(procedure, arguments)
      case procedure.type
      when :procedure_primitive
        procedure.apply(arguments)
      when :procedure_compound
        apply_compound_procedure(procedure, arguments)
      else
        raise Error, "Unknown procedure type -- APPLY: got=%s" % procedure.type.to_s
      end
    end

    private

    EV_SELF_EVALUATING = [:ast_string, :ast_number,]
    EV_VARIABLE        = [:ast_identifier]
    EV_QUOTED          = [:ast_quotation]
    EV_ASSIGNMENT      = [:ast_assignment]
    EV_DEFINITION      = [:ast_identifier_definition]
    EV_IF              = [:ast_conditional]
    EV_LAMBDA          = [:ast_lambda_expression]
    EV_BEGIN           = [:ast_begin]
    EV_COND            = [:ast_cond]
    EV_APPLICATION     = [:ast_procedure_call]

    def eval_boolean(ast_node, _)
      case ast_node.literal
      when /\A#f(alse)?\Z/
        false
      when /\A#t(rue)?\Z/
        true
      else
        raise Error, "Invalid boolean literal -- EVAL: got=%s" % exp[1]
      end
    end

    def eval_self_evaluating(ast_node, _)
      if ast_node.type == :ast_number and /([^\/]+)\/([^\/]+)/ === ast_node.literal
        md = Regexp.last_match
        Kernel.eval("Rational(#{md[1]}, #{md[2]})")
      else
        Kernel.eval(ast_node.literal)
      end
    end

    def text_of_quotation(ast_node)
      "not implemented yet"
    end

    def eval_assignment(ast_node, env)
      var = identifier(ast_node.identifier)
      val = self.eval(ast_node.expression, env)
      env.set_variable(var, val)
    end

    def eval_definition(ast_node, env)
      var = identifier(ast_node.identifier)
      val = self.eval(ast_node.expression, env)
      env.define_variable(var, val)
    end

    def eval_if(ast_node, env)
      if true?(self.eval(ast_node.test, env))
        self.eval(ast_node.consequent, env)
      else
        self.eval(ast_node.alternate, env) if ast_node.alternate?
      end
    end

    def true?(ast_boolean)
      self.eval_boolean(ast_boolean, nil)
    end

    def make_procedure(parameters, body, env)
      Procedure.make_procedure(parameters, body, env)
    end

    def eval_sequence(ast_nodes, env)
      value = nil
      if ast_nodes.instance_of?(Array) && ast_nodes.size > 0
        value = self.eval(ast_nodes[0], env)
        value = eval_sequence(ast_nodes[1..-1], env) if ast_nodes.size > 1
      end
      value
    end

    def eval_let(ast_node, env)
      # <named let> is not supported yet.
      formals = Rubasteme::AST.instantiate(:ast_formals, nil)
      operands = []
      ast_node.bindings.each { |bind_spec|
        formals.add_identifier(bind_spec.identifier)
        operands << bind_spec.expression
      }
      procedure = make_procedure(formals, ast_node.body, env)
      apply(procedure, list_of_values(operands, env))
    end

    def list_of_values(ast_nodes, env)
      ast_nodes.map{|node| self.eval(node, env)}
    end

    def apply_compound_procedure(procedure, arguments)
      base_env = procedure.env
      extended_env = base_env.extend(procedure_parameters(procedure),
                                     arguments)
      eval_sequence(procedure_body(procedure), extended_env)
    end

    def procedure_parameters(procedure)
      procedure.parameters.map{|node| identifier(node)}
    end

    def procedure_body(procedure)
      procedure.body
    end

  end
end
