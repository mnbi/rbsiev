# frozen_string_literal: true

module Rbsiev

  module Primitives

    require_relative "primitives/empty_list"
    require_relative "primitives/comparison"
    require_relative "primitives/arithmetic"

    include EmptyList
    include Comparison
    include Arithmetic

    def cons(scm_obj1, scm_obj2)
      [obj1, obj2]
    end

    def pair?(scm_obj)
      scm_obj.instance_of?(Array)
    end

    def list?(scm_obj)
      scm_obj.instance_of?(Array)
    end

    def car(scm_list)
      scm_list[0]
    end

    def cdr(scm_list)
      scm_list[1..-1]
    end

    def list(*scm_objs)
      scm_objs
    end

    def append(*scm_lists)
      if scm_lists.empty?
        SCM_EMPTY_LIST
      else
        scm_lists[0] + append(*scm_lists[1..-1])
      end
    end

    def write(scm_obj)
      print scm_obj
    end

    def display(scm_obj)
      write(scm_obj)
      print "\n"
    end

    def number?(scm_obj)
      scm_obj.kind_of?(Numeric) ? SCM_TRUE : SCM_FALSE
    end

  end

end
