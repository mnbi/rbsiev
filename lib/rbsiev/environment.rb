# frozen_string_literal: true

module Rbsiev

  class Environment
    include Primitives

    def self.the_empty_environment
      Environment.new
    end

    def self.make_frame(variables, values)
      variables.zip(values).to_h
    end

    def self.frame_variables(frame)
      frame.keys
    end

    def self.frame_valeus(frame)
      frame.values
    end

    def self.add_binding_to_frame(var, val, frame)
      frame.merge!({var => val})
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

    def initialize
      @frames = []
    end
    protected :initialize

    attr_reader :frames

    def enclosing_environment
      @frames[1..-1]
    end

    def first_frame
      @frames[0]
    end

    def extend(vars, vals)
      if vars.size == vals.size
        @frames.unshift(Environment.make_frame(vars, vals))
      elsif var.size < vals.size
        raise Error, "Too many arguments supplied: %s => %s" % [vars, vals]
      else
        raise Error, "Too few arguments supplied: %s => %s" % [vars, vals]
      end
      self
    end

    def lookup_variable_value(var)
      val = nil
      @frames.each { |frame|
        if frame.key?(var)
          val = frame[var]
          break
        end
      }
      raise Error, "Unbound variable: got=%s" % (var || "nil") if val.nil?
      val
    end

    def define_variable(var, val)
      frame = first_frame || {}
      Environment.add_binding_to_frame(var, val, frame)
      var
    end

    def set_variable_value(var, val)
      frame = @frames.find{|f| f.key?(var)}
      raise Error, "Unbound variable: got=%s" % var if frame.nil?
      frame[var] = val
      val
    end

  end                           # end of Environment

end
