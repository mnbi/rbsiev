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

      # For AST::BeginNode.

      def begin_action(ast_node)
        check_type(:ast_begin, ast_node)
        ast_node.elements
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

      def sequence_to_node(nodes)
        check_list_type(nodes)
        if nodes.empty?
          EMPTY_LIST
        elsif last_node?(nodes)
          first_node(nodes)
        else
          make_begin(nodes)
        end
      end

      def let_star_to_nested_lets(bindings, body)
        single_bindings = make_bindings([first_binding(bindings)])
        if last_binding?(bindings)
          make_let(single_bindings, body)
        else
          make_let(single_bindings,
                   let_star_to_nested_lets(rest_bindings(bindings), body))
        end
      end

      # Construcing functions.

      def make_begin(nodes)
        begin_node = Rubasteme::AST.instantiate(:ast_begin, nil)
        nodes.each{|node| begin_node << node}
        begin_node
      end

      def make_if(predicate, consequent, alternative)
        if_node = Rubasteme::AST.instantiate(:ast_conditional, nil)
        if_node.test = predicate
        if_node.consequent = consequent
        if_node.alternate = alternative if alternative
        if_node
      end

      def make_let(bindings, body)
        check_type(:ast_bindings, bindings)
        let_node = Rubasteme::AST.instantiate(:ast_let, nil)
        let_node.bindings = bindings
        let_node.body = body.instance_of?(Array) ? body : [body]
        let_node
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
        test = clause_node.test
        test.type == :ast_identifier && identifier(test) == "else"
      end

    end                         # end of Misc
  end                           # end of AST
end
