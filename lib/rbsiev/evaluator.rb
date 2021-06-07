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
      self.send(func_map(ast_node.type), ast_node, env)
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

    EV_FUNCTIONS_MAP = {
      ast_empty_list:        :eval_empty_list,
      ast_boolean:           :eval_boolean,
      ast_identifier:        :eval_variable,
      ast_character:         :eval_self_evaluating,
      ast_string:            :eval_self_evaluating,
      ast_number:            :eval_self_evaluating,
      ast_program:           :eval_program,
      ast_quotation:         :eval_quoted,
      ast_procedure_call:    :eval_combination,
      ast_lambda_expression: :eval_lambda,
      ast_conditional:       :eval_if,
      ast_assignment:        :eval_assignment,
      ast_identifier_definition: :eval_definition,
      ast_cond:              :eval_cond,
      ast_and:               :eval_and,
      ast_or:                :eval_or,
      ast_when:              :eval_when,
      ast_unless:            :eval_unless,
      ast_let:               :eval_let,
      ast_let_star:          :eval_let_star,
      ast_letrec:            :eval_letrec,
      ast_letrec_star:       :eval_letrec_star,
      ast_begin:             :eval_begin,
      ast_do:                :eval_do,
    }

    def func_map(ast_node_type)
      func = EV_FUNCTIONS_MAP[ast_node_type]
      if func.nil?
        raise Error, "Unknown expression type -- EVAL: got=%s" % ast_node_type
      end
      func
    end

    def eval_empty_list(_ast_node, _env)
      SCM_EMPTY_LIST
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

    def eval_variable(ast_node, env)
      env.lookup_variable_value(identifier(ast_node))
    end

    def eval_self_evaluating(ast_node, env)
      if ast_node.type == :ast_number and /([^\/]+)\/([^\/]+)/ === ast_node.literal
        md = Regexp.last_match
        Kernel.eval("Rational(#{md[1]}, #{md[2]})")
      else
        Kernel.eval(ast_node.literal)
      end
    end

    def eval_program(ast_node, env)
      result = nil
      ast_node.each { |node|
        result = self.eval(node, env)
      }
      result
    end

    def eval_quoted(ast_node, _env)
      text_of_quotation(ast_node)
    end

    def eval_combination(ast_node, env)
      apply(self.eval(ast_node.operator, env),
            list_of_values(ast_node.operands, env))
    end

    def eval_lambda(ast_node, env)
      parameters = ast_node.formals.map{|e| identifier(e)}
      dummy_arguments = Array.new(parameters.size, :ev_unassigned)
      extended_env = env.extend(parameters, dummy_arguments)

      definitions = ast_node.body.definitions
      unless definitions.empty?
        names = []
        procedures = []
        definitions.each { |definition|
          name = identifier(definition.identifier)
          extended_env.define_variable(name, :ev_unassigned)

          self.eval(definition, extended_env)

          names << name
          procedures << extended_env.lookup_variable_value(name)
        }

        target_frame = extended_env.first_frame
        names.zip(procedures).each { |name, procedure|
          target_frame.set(name, procedure)
        }
      end

      make_procedure(ast_node.formals, ast_node.body.sequence, extended_env)
    end

    def eval_if(ast_node, env)
      test_result = self.eval(ast_node.test, env)
      if true?(test_result)
        self.eval(ast_node.consequent, env)
      else
        self.eval(ast_node.alternate, env) if ast_node.alternate?
      end
    end

    def eval_assignment(ast_node, env)
      var = identifier(ast_node.identifier)
      val = self.eval(ast_node.expression, env)
      env.set_variable_value(var, val)
    end

    def eval_definition(ast_node, env)
      var = identifier(ast_node.identifier)
      val = self.eval(ast_node.expression, env)
      env.define_variable(var, val)
    end

    def eval_cond(ast_node, env)
      eval_if(cond_to_if(ast_node), env)
    end

    def eval_and(ast_node, env)
      if empty_node?(ast_node)
        SCM_TRUE
      else
        result = self.eval(first_node(ast_node), env)
        if true?(result)
          if last_node?(ast_node)
            result
          else
            self.eval_and(rest_nodes(ast_node), env)
          end
        else
          SCM_FALSE
        end
      end
    end

    def eval_or(ast_node, env)
      if empty_node?(ast_node)
        SCM_FALSE
      else
        result = self.eval(first_node(ast_node), env)
        if true?(result)
          result
        else
          if last_node?(ast_node)
            SCM_FALSE
          else
            self.eval_or(rest_nodes(ast_node), env)
          end
        end
      end
    end

    def eval_when(ast_node, env)
      test_result = self.eval(ast_node.test, env)
      if true?(test_result)
        self.eval_sequence(ast_node.sequence, env)
      end
    end

    def eval_unless(ast_node, env)
      test_result = self.eval(ast_node.test, env)
      unless true?(test_result)
        self.eval_sequence(ast_node.sequence, env)
      end
    end

    def eval_let(ast_node, env)
      combination = let_to_combination(ast_node)

      # named let
      if ast_node.identifier
        name = identifier(ast_node.identifier)
        extended_env = env.extend([name], [:ev_unassigned])
        procedure = self.eval(combination.operator, extended_env)
        extended_env.set_variable_value(name, procedure)
        env = extended_env
        combination.operator = make_identifier(name)
      end

      self.eval(combination, env)
    end

    def eval_let_star(ast_node, env)
      nested_lets = let_star_to_nested_lets(ast_node.bindings,
                                            ast_node.body)
      self.eval(nested_lets, env)
    end

    def eval_letrec(ast_node, env)
      combination = let_to_combination(ast_node)

      params = parameters(combination.operator.formals)
      ext_env = env.extend(params, Array.new(params.size, :ev_unassigned))

      target_frame = ext_env.first_frame

      operands = combination.operands.map{|e| self.eval(e, ext_env)}
      params.zip(operands).each { |parameter, arg|
        target_frame.set(parameter, arg)
      }

      self.eval(combination, ext_env)
    end

    def eval_letrec_star(ast_node, env)
      combination = let_to_combination(ast_node)

      params = parameters(combination.operator.formals)
      ext_env = env.extend(params, Array.new(params.size, :ev_unassigned))

      target_frame = ext_env.first_frame

      params.zip(combination.operands).each { |parameter, operand|
        arg = self.eval(operand, ext_env)
        target_frame.set(parameter, arg)
      }

      self.eval(combination, ext_env)
    end

    def eval_begin(ast_node, env)
      eval_sequence(ast_node.sequence, env)
    end

    def eval_sequence(ast_node, env)
      value = nil
      ast_node.each{|exp| value = self.eval(exp, env)}
      value
    end

    EV_DO_LOOP_NAME = "ev_do_loop"

    def eval_do(ast_node, env)
      let_node = do_to_named_let(ast_node, EV_DO_LOOP_NAME)
      self.eval(let_node, env)
    end

    def text_of_quotation(ast_node)
      "not implemented yet"
    end

    def true?(obj)
      case obj
      when Scmo::Object
        obj.to_rb == false ? false : true
      when Rubasteme::AST::BooleanNode
        self.eval_boolean(obj, nil)
      when FalseClass, NilClass
        false
      when TrueClass
        true
      else
        true
      end
    end

    def make_procedure(parameters, seq, env)
      Procedure.make_procedure(parameters, seq, env)
    end

    def list_of_values(ast_nodes, env)
      ast_nodes.map{|node| self.eval(node, env)}
    end

    def apply_compound_procedure(procedure, arguments)
      env = procedure.env
      procedure_parameters(procedure).zip(arguments).each { |var, val|
        env.set_variable_value(var, val)
      }
      eval_sequence(procedure_body(procedure), env)
    end

    def procedure_parameters(procedure)
      procedure.parameters.map{|node| identifier(node)}
    end

    def procedure_body(procedure)
      procedure.body
    end

  end
end
