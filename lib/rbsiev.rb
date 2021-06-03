# frozen_string_literal: true

require "rbscmlex"
require "rubasteme"
require_relative "rubasteme/ast/misc"
require_relative "scmo/object"

module Rbsiev
  require_relative "rbsiev/version"
  require_relative "rbsiev/error"
  require_relative "rbsiev/primitives"
  require_relative "rbsiev/procedure"
  require_relative "rbsiev/environment"
  require_relative "rbsiev/evaluator"
  require_relative "rbsiev/printer"
  require_relative "rbsiev/repl"

  SCM_EMPTY_LIST = Scmo::EMPTY_LIST
  SCM_TRUE = Scmo::TRUE
  SCM_FALSE = Scmo::FALSE

  def self.scheme_object?(obj)
    Scmo.scheme_object?(obj)
  end

  Components = Struct.new(:parser, :evaluator, :printer, :env) {
    def parse(source)
      parser.parse(Rbscmlex.lexer(source))
    end

    def eval(ast_node)
      evaluator.eval(ast_node, env)
    end

    def print(value)
      printer.print(value)
    end

    def exec(source)
      self.print(self.eval(parse(source)))
    end

    def load(file)
      raise Error, "Cannot find \"%s\"" % f unless FileTest.exist?(file)
      source = File.readlines(file, chomp: true).join(" ")
      self.exec(source)
    end

    def version
      comp_vers = []
      comp_vers << Rbscmlex::Lexer.version
      comp_vers << Rubasteme::Parser.version
      comp_vers << Evaluator.version
      comp_vers.join("\n")
    end
  }

  def self.evaluator
    Evaluator.new
  end

  def self.printer
    Printer.new
  end

  def self.setup_environment
    initial_env = Environment.the_empty_environment
    names = []
    values = []
    PRIMITIVE_NAMES_MAP.each { |name, sym|
      names << name
      values << Procedure.make_procedure(nil, sym, initial_env)
    }
    initial_env.extend(names, values)
  end

  def self.eval(scm_source)
    lexer = Rbscmlex.lexer(scm_source)
    parser = Rubasteme.parser
    eva = evaluator
    env = setup_environment
    eva.eval(parser.parse(lexer), env)
  end

  def self.run(files:, verbose: false)
    parser = Rubasteme.parser
    evaluator = Evaluator.new
    env = setup_environment
    printer = Printer.new

    evaluator.verbose = verbose
    printer.verbose = verbose

    components = Components.new(parser, evaluator, printer, env)

    files.each {|f| components.load(f)}
  end
end
