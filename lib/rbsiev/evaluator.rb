# frozen_string_literal: true

module Rbsiev
  class Evaluator

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

    def identifier(ast_node)
      if ast_node.type == :ast_identifier
        ast_node.literal
      end
    end

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
        eval_sequence(ast_nodes[1..-1], env) if ast_nodes.size > 1
      end
      value
    end

    def begin_action(ast_node)
      ast_node.each.to_a
    end

    def last_node?(seq)
      rest = rest_node(seq)
      rest && rest.empty?
    end

    def first_node(seq)
      seq[0]
    end

    def rest_node(seq)
      seq[1..-1]
    end

    def sequence_to_node(seq)
      if seq.empty?
        EMPTY_LIST
      elsif last_node?(seq)
        first_node(seq)
      else
        make_begin(seq)
      end
    end

    def make_begin(seq)
      node = Rubasteme::AST.instantiate(:ast_begin, nil)
      seq.each{|e| node << e}
      node
    end

    def cond_to_if(ast_node)
      expand_clauses(ast_node.cond_clauses)
    end

    def expand_clauses(clauses)
      if clauses.empty?
        SCM_FALSE
      else
        first = clauses[0]
        rest = clauses[1..-1]
        if cond_else_clause(first)
          if rest.empty?
            sequence_to_node(first.sequence)
          else
            raise Error,
                  "ELSE clause isn't last -- COND_TO_IF: got=%s" % clauses
          end
        else
          make_if(first.test,
                  sequence_to_node(first.sequence),
                  expand_clauses(rest))
        end
      end
    end

    def cond_else_clause(clause_node)
      test = clause_node.test
      test.type == :ast_identifier && identifier(test) == "else"
    end

    def make_if(predicate, consequent, alternative)
      node = Rubasteme::AST.instantiate(:ast_conditional, nil)
      node.test = predicate
      node.consequent = consequent
      node.alternate = alternative if alternative
      node
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
