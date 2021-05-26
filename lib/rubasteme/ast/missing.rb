# frozen_string_literal: true

module Rubasteme
  module AST

    # :stopdoc:

    # This file contains methods those should be part of a AST node
    # class.  They would be moved into Rubasteme project in some time.

    # :startdoc:

    class ListNode
      def empty?
        @nodes.empty?
      end

      def first
        @nodes[0]
      end

      def rest
        @nodes[1..-1]
      end

      def elements
        @nodes
      end
    end
  end                           # end of AST
end
