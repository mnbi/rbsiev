# frozen_string_literal: true

require "readline"

module Rbsiev

  class Repl
    def self.start(prompt: "REPL> ", verbose: false)
      msg = Repl.new(prompt: prompt, verbose: verbose).loop
      puts msg if msg
    end

    def initialize(prompt:, verbose: false)
      @verbose = verbose
      @prompt = prompt
    end

    def loop
      parser = Rubasteme.parser
      evaluator = Evaluator.new
      env = Rbsiev.setup_environment
      printer = Printer.new

      evaluator.verbose = @verbose
      printer.verbose = @verbose

      components = Components.new(parser, evaluator, printer, env)

      func_map = {
        load: lambda{|file| components.load(file)},
        version: lambda{components.version},
      }

      procedures = []
      func_map.each { |sym, func|
        env.define_singleton_method(sym, func)
        procedures << Procedure.make_procedure(nil, sym, env)
      }
      env = env.extend(func_map.keys.map(&:to_s), procedures)
      components.env = env

      msg = Kernel.loop {
        source = Readline::readline(@prompt, true)
        break "Bye!" if source.nil?

        begin
          components.exec(source)
        rescue Error => e
          puts e.message
          next
        end
      }
      msg
    end

    private

  end

end
