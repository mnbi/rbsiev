# frozen_string_literal: true

module Rbsiev

  class Environment
    include Primitives

    def self.the_empty_environment
      Environment.new(nil)
    end

    PRIMITIVE_PROCEDURE_NAME_MAP = {
      "cons" => :cons,
      "list" => :list,
      "pair?" => :pair?,
      "list?" => :list?,
      "car" => :car,
      "cdr" => :cdr,
      "display" => :display,
      "write" => :write,
      "append" => :append,
      "number?" => :number?,
      "zero?" => :zero?,
      "+" => :add,
      "-" => :subtract,
      "*" => :mul,
      "/" => :div,
      "scm_true" => :scm_true,
      "scm_false" => :scm_false,
      "<" => :lt?,
      "<=" => :le?,
      ">" => :gt?,
      ">=" => :ge?,
      "=" => :same_value?,
    }

    def self.primitive_procedure_names
      PRIMITIVE_PROCEDURE_NAME_MAP.keys
    end

    def self.primitive_procedure_objects(env)
      # to preserve the order of names
      primitive_procedure_names.map { |name|
        sym = PRIMITIVE_PROCEDURE_NAME_MAP[name]
        Procedure.make_procedure(nil, sym, env)
      }
    end

    class Frame
      def initialize(variables, values)
        @bindings = variables.zip(values).to_h
      end

      def defined?(var)
        @bindings.key?(var)
      end

      def [](var)
        @bindings[var]
      end

      def []=(var, val)
        @bindings[var] = val
      end

      def variables
        @bindings.keys
      end

      def values
        @bindings.values
      end

      def add_binidng(var, val)
        self[var] = val
      end
    end

    def initialize(base_env = nil)
      @frame = nil
      @enclosing_environment = base_env
      @verbose = false
    end

    attr_reader :frame
    attr_reader :enclosing_environment

    def extend(vars, vals)
      if vars.size == vals.size
        extended_env = Environment.new(self)
        extended_env.make_frame(vars, vals)
        extended_env
      elsif var.size < vals.size
        raise Error, "Too many arguments supplied: %s => %s" % [vars, vals]
      else
        raise Error, "Too few arguments supplied: %s => %s" % [vars, vals]
      end
    end

    def lookup_variable_value(var)
      value, _ = lookup_value_and_environment(var)
      raise Error, "Unbound variable: got=%s" % (var || "nil") if value.nil?
      value
    end

    def define_variable(var, val)
      if @frame
        @frame[var] = val
      else
        @frame = make_frame([var], [val])
      end
      var
    end

    def set_variable(var, val)
      _, env = lookup_value_and_environment(var)
      if env
        env.frame[var] = val
      else
        raise Error, "Unbound variable: got=%s" % var
      end
      val
    end

    protected

    def make_frame(variables, values)
      @frame = Frame.new(variables, values)
    end

    private

    def lookup_value_and_environment(var)
      value = nil
      env = self
      while env
        if env.frame && env.frame.defined?(var)
          value = env.frame[var]
          break
        end
        env = env.enclosing_environment
      end
      [value, env]
    end

  end                           # end of Environment

end
