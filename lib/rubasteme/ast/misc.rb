# frozen_string_literal: true

module Rubasteme
  module AST

    # Miscellaneous functions to operate AST nodes.

    module Misc

      # For AST::IdentifierNode.

      def identifier(ast_node)
        if ast_node.respond_to?(:literal)
          ast_node.literal
        else
          raise Error, "wrong type node: got=%s" % ast_node.to_a.to_s
        end
      end

      # For AST::ListNode.  They also accept an Array object as their
      # arugment.

      def empty_node?(obj)
        check_list_type(obj)
        obj.empty?
      end

      def last_node?(obj)
        check_list_type(obj)
        obj.size == 1
      end

      def first_node(obj)
        check_list_type(obj)
        obj[0]
      end

      def rest_nodes(obj)
        check_list_type(obj)
        obj[1..-1]
      end

      def list_elements(obj)
        case obj
        when ListNode
          obj.elements
        when Array
          obj
        else
          raise Error, "wrong type node: expected=(Array or ListNode), got=%s" % obj.to_a.to_s
        end
      end

      # for AST::FormalsNode

      def parameters(ast_node)
        check_type(:ast_formals, ast_node)
        ast_node.map{|e| identifier(e)}
      end

      # For AST::BindingsNode

      def last_binding?(ast_node)
        last_node?(list_elements(ast_node))
      end

      def first_binding(ast_node)
        first_node(ast_node)
      end

      def rest_bindings(ast_node)
        make_bindings(rest_nodes(ast_node))
      end

      def bindings_specs(ast_node)
        check_type(:ast_bindings, ast_node)
        ast_node.elements
      end

      # Converter function.

      def cond_to_if(ast_node)
        check_type(:ast_cond, ast_node)
        expand_clauses(ast_node.cond_clauses)
      end

      def sequence_to_node(ast_node)
        check_type(:ast_sequence, ast_node)
        if ast_node.empty?
          EMPTY_LIST
        elsif last_node?(ast_node)
          first_node(ast_node)
        else
          make_begin(ast_node)
        end
      end

      def let_to_combination(ast_node)
        check_types([:ast_let, :ast_letrec, :ast_letrec_star], ast_node)

        identifiers = []
        operands = []

        ast_node.bindings.each { |bind_spec|
          identifiers << bind_spec.identifier
          operands << bind_spec.expression
        }

        formals = make_formals(identifiers)
        operator = make_lambda(formals, ast_node.body)

        make_combination(operator, operands)
      end

      def let_star_to_nested_lets(bindings, body)
        single_bindings = make_bindings([first_binding(bindings)])
        if last_binding?(bindings)
          make_let(single_bindings, body)
        else
          seq = make_sequence([let_star_to_nested_lets(rest_bindings(bindings), body)])
          new_body = make_body(nil, seq)
          make_let(single_bindings, new_body)
        end
      end

      def do_to_named_let(ast_node, loop_identifier)
        bind_specs = []
        bind_specs_with_step = []
        ast_node.iteration_bindings.each { |iter_spec|
          spec = make_bind_spec(iter_spec.identifier, iter_spec.init)
          if iter_spec.step
            bind_specs_with_step << [spec, iter_spec.step]
          else
            bind_specs << spec
          end
        }

        let_bindings = make_bindings(bind_specs_with_step.map{|e| e[0]})

        test_and_do_result = ast_node.test_and_do_result

        if_predicate = test_and_do_result.test
        if_consequent = make_begin(rest_nodes(test_and_do_result))

        sequence = []
        sequence += ast_node.commands
        sequence << make_combination(make_identifier(loop_identifier),
                                     bind_specs_with_step.map{|e| e[1]})
        if_alternative = make_begin(sequence)

        if_node = make_if(if_predicate, if_consequent, if_alternative)
        let_body = make_body(nil, make_sequence([if_node]))
        let_node = make_let(let_bindings, let_body)
        let_node.identifier = make_identifier(loop_identifier)

        if bind_specs.empty?
          let_node
        else
          let_body = make_body(nil, make_sequence([let_node]))
          make_let(make_bindings(bind_specs), let_body)
        end
      end

      # Construcing functions.

      def make_identifier(literal)
        Rubasteme::AST::instantiate(:ast_identifier, literal)
      end

      def make_lambda(formals, body)
        check_type(:ast_body, body)
        lambda_node = Rubasteme::AST.instantiate(:ast_lambda_expression, nil)
        lambda_node.formals = formals
        lambda_node.body = body
        lambda_node
      end

      def make_begin(nodes)
        begin_node = Rubasteme::AST.instantiate(:ast_begin, nil)
        case nodes
        when Rubasteme::AST::SequenceNode
          begin_node.sequence = nodes
        when Array
          begin_node.sequence = make_sequence(nodes)
        else
          raise Error, "wrong type argument: expected= Array or Rubasteme::AST::SequenceNode, got=%s" % nodes.class
        end
        begin_node
      end

      def make_body(definitions, sequence)
        body_node = Rubasteme::AST.instantiate(:ast_body, nil)

        if definitions.nil?
          definitions = Rubasteme::AST.instantiate(:ast_internal_definitions, nil)
        end
        if sequence.nil?
          sequence = Rubasteme::ASt.instantiate(:ast_sequence, nil)
        end

        body_node.definitions = definitions
        body_node.sequence = sequence

        body_node
      end

      def make_sequence(nodes)
        check_list_type(nodes)
        seq_node = Rubasteme::AST.instantiate(:ast_sequence, nil)
        nodes.each{|exp| seq_node.add_expression(exp)}
        seq_node
      end

      def make_if(predicate, consequent, alternative)
        if_node = Rubasteme::AST.instantiate(:ast_conditional, nil)
        if_node.test = predicate
        if_node.consequent = consequent
        if_node.alternate = alternative if alternative
        if_node
      end

      def make_formals(identifiers)
        formals_node = Rubasteme::AST.instantiate(:ast_formals, nil)
        identifiers.each { |identifier_node|
          check_type(:ast_identifier, identifier_node)
          formals_node.add_identifier(identifier_node)
        }
        formals_node
      end

      def make_combination(operator, operands)
        proc_call_node = Rubasteme::AST.instantiate(:ast_procedure_call, nil)
        proc_call_node.operator = operator
        operands.each { |node|
          proc_call_node.add_operand(node)
        }
        proc_call_node
      end

      def make_let(bindings, body)
        check_type(:ast_bindings, bindings)
        check_type(:ast_body, body)
        let_node = Rubasteme::AST.instantiate(:ast_let, nil)
        let_node.bindings = bindings
        let_node.body = body
        let_node
      end

      def make_bind_spec(identifier, expression)
        spec_node = Rubasteme::AST.instantiate(:ast_bind_spec, nil)
        spec_node.identifier = identifier
        spec_node.expression = expression
        spec_node
      end

      def make_bindings(bind_spec_nodes)
        bindings_node = Rubasteme::AST.instantiate(:ast_bindings, nil)
        bind_spec_nodes.each { |spec|
          check_type(:ast_bind_spec, spec)
          bindings_node.add_bind_spec(spec)
        }
        bindings_node
      end

      private

      def check_list_type(obj)
         obj.kind_of?(ListNode) || obj.kind_of?(Array)
      end

      def check_type(ast_type, ast_node)
        if ast_node.type != ast_type
          raise Error,
                "wrong type node: expected=%s, got=%s" % [ast_type, ast_node.to_a.to_s]
        end
      end

      def check_types(types, ast_node)
        unless types.include?(ast_node.type)
          raise Error,
                "wrong type node: expected=%s, got=%s" % [ast_type, ast_node.to_a.to_s]
        end
      end

      def expand_clauses(clauses)
        # clauses must be an Array which holds CondClauseNode.
        if clauses.empty?
          SCM_FALSE
        else
          first = first_node(clauses)
          rest = rest_nodes(clauses)
          if cond_else_clause?(first)
            if rest.empty?
              sequence_to_node(first.sequence)
            else
              raise Error,
                    "ELSE clause isn't last: got=%s" % clauses.to_s
            end
          else
            make_if(first.test,
                    sequence_to_node(first.sequence),
                    expand_clauses(rest))
          end
        end
      end

      def cond_else_clause?(clause_node)
        clause_node.type == :ast_else_clause
      end

    end                         # end of Misc
  end                           # end of AST
end
