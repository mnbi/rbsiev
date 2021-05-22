# frozen_string_literal: true

module Rbsiev
  module Primitives

    module EmptyList

      SCM_EMPTY_LIST = []

      def null?(scm_obj)
        scm_obj.instance_of?(Array) && scm_obj.empty?
      end

    end

  end
end
