# frozen_string_literal: true

require "rbscmlex"
require "rubasteme"

module Rbsiev
  require_relative "rbsiev/version"
  require_relative "rbsiev/error"
  require_relative "rbsiev/primitives"
  require_relative "rbsiev/procedure"
  require_relative "rbsiev/environment"
  require_relative "rbsiev/evaluator"
  require_relative "rbsiev/printer"
  require_relative "rbsiev/repl"

  SCM_EMPTY_LIST = Primitives::EmptyList::SCM_EMPTY_LIST
  SCM_TRUE = Rubasteme::AST.instantiate(:ast_boolean, "#t")
  SCM_FALSE = Rubasteme::AST.instantiate(:ast_boolean, "#f")

  Components = Struct.new(:parser, :evaluator, :printer, :env) {
    def parse(lexer)
      parser.parse(lexer)
    end

    def eval(ast_node)
      evaluator.eval(ast_node, env)
    end

    def print(value)
      printer.print(value)
    end

    def exec(source)
      lexer = Rbscmlex::Lexer.new(source)
      result_value = self.eval(parse(lexer))
      self.print(result_value)
    end

    def load(file)
      raise Error, "Cannot find \"%s\"" % f unless FileTest.exist?(file)
      source = File.readlines(file, chomp: true).join(" ")
      self.exec(source)
    end

    def version
      comp_vers = []
      comp_vers << Rbscmlex::Lexer.version
      comp_vers << "(#{Rubasteme::Parser.version})"
      comp_vers << Evaluator.version
      comp_vers.join("\n")
    end
  }

  def self.setup_environment
    initial_env = Environment.the_empty_environment
    names = Environment.primitive_procedure_names
    values = Environment.primitive_procedure_values(initial_env)
    initial_env.extend(names, values)
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
