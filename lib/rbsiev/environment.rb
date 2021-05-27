# frozen_string_literal: true

module Rbsiev

  class Environment
    include Primitives

    def self.the_empty_environment
      Environment.new(nil)
    end

    def self.make_frame(variables, values)
      variables.zip(values).to_h
    end

    def self.frame_variables(frame)
      frame && frame.keys
    end

    def self.frame_valeus(frame)
      frame && frame.values
    end

    def self.lookup_variable_value(var, frame)
      frame && frame[var]
    end

    def self.add_binding_to_frame(var, val, frame)
      frame && frame.merge!({var => val})
    end

    def self.set_variable_value(var, val, frame)
      frame && frame[var] = val
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

    def initialize(base_env)
      @frame = nil
      @enclosing_environment = base_env
    end

    attr_reader :enclosing_environment

    def first_frame
      @frame
    end

    def extend(vars, vals)
      if vars.size == vals.size
        new_env = Environment.new(self)
        new_env.set_frame!(Environment.make_frame(vars, vals))
        new_env
      elsif var.size < vals.size
        raise Error, "Too many arguments supplied: %s => %s" % [vars, vals]
      else
        raise Error, "Too few arguments supplied: %s => %s" % [vars, vals]
      end
    end

    def lookup_variable_value(var)
      val = nil
      env = self
      while env
        val = Environment.lookup_variable_value(var, env.first_frame)
        break if val
        env = env.enclosing_environment
      end
      raise Error, "Unbound variable: got=%s" % var if val.nil?
      val
    end

    def define_variable(var, val)
      if first_frame.nil?
        set_frame!(Environment.make_frame([var], [val]))
      else
        Environment.add_binding_to_frame(var, val, first_frame)
      end
      var
    end

    def set_variable_value(var, val)
      current = nil
      env = self
      while env
        current = Environment.lookup_variable_value(var, env.first_frame)
        if current
          Environment.set_variable_value(var, val, env.first_frame)
          break
        else
          env = env.enclosing_environment
        end
      end
      raise Error, "Unbound variable: got=%s" % var if current.nil?
      val
    end

    protected

    def set_frame!(frame)
      @frame = frame
    end

  end                           # end of Environment

end
