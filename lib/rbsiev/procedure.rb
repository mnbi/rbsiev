# frozen_string_literal: true

module Rbsiev
  class Procedure
    def self.make_procedure(parameters, body, env)
      if body.instance_of?(Symbol)
        PrimitiveProcedure.new(nil, body, env)
      else
        CompoundProcedure.new(parameters, body, env)
      end
    end

    attr_reader :parameters
    attr_reader :body
    attr_reader :env

    def type; nil; end
    def apply(arguments); end

    protected

    def initialize(parameters, body, env)
      @parameters = parameters
      @body = body
      @env = env
    end
  end

  class PrimitiveProcedure < Procedure
    def type; :procedure_primitive; end
    def apply(arguments)
      @env.send(@body, *arguments)
    end
  end

  class CompoundProcedure < Procedure
    def type; :procedure_compound; end
  end

end
