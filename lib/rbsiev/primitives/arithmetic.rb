# frozen_string_literal: true

module Rbsiev

  module Primitives

    module Arithmetic

      def zero?(obj)
        if number?(obj) == SCM_TRUE
          same_value?(obj, 0)
        else
          SCM_FALSE
        end
      end

      def add(*args)
        a_calc(:+, *args)
      end

      def subtract(*args)
        a_calc(:-, *args)
      end

      def mul(*args)
        a_calc(:*, *args)
      end

      def div(*args)
        a_calc(:/, *args)
      end

      def mod(*args)
        a_calc(:%, *args)
      end

      private

      def a_calc(op, *args)
        case args.size
        when 0
          0
        when 1
          args[0]
        else
          a_calc(op, args[0].send(op, args[1]), *args[2..-1])
        end
      end

    end                         # end of Arithmetic

  end                           # end of Primitives

end
