# frozen_string_literal: true

module Rbsiev
  module Primitives

    module EmptyList

      def null?(scm_obj)
        scm_obj.kind_of?(Scmo::Object) && scm_obj.null?
      end

    end

  end
end
