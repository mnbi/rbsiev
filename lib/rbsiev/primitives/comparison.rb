# frozen_string_literal: true

module Rbsiev

  module Primitives

    module Comparison

      def lt?(*args)
        c_calc(:<, *args)
      end

      def le?(*args)
        c_calc(:<=, *args)
      end

      def gt?(*args)
        c_calc(:>, *args)
      end

      def ge?(*args)
        c_calc(:>=, *args)
      end

      def same_value?(*args)
        c_calc(:==, *args)
      end

      private

      def c_calc(op, *args)
        case args.size
        when 0, 1
          raise Error, "Too few arguments: got=%s" % scm_objs
        when 2
          args[0].send(op, args[1]) ? SCM_TRUE : SCM_FALSE
        else
          args[0].send(op, args[1]) and c_calc(op, *args[1..-1]) ? SCM_TRUE : SCM_FALSE
        end
      end

    end                         # end of Comparison

  end                           # end of Primitives

end
