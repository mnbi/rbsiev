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
      @components = init_components
    end

    def loop
      second_prompt = "." * (@prompt.length - 1) + " "

      msg = Kernel.loop {
        begin
          source = read_source(second_prompt)
        rescue EOFError => _
          break "Bye!"
        else
          next if source.nil?
        end

        begin
          @components.exec(source)
        rescue Error => e
          puts e.message
          next
        end
      }
      msg
    end

    private

    def init_components
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

      components
    end

    def read_source(second_prompt = ">> ")
      source = Readline::readline(@prompt, true)
      raise EOFError if source.nil?

      until match_parenthesis(source)
        more_source = Readline::readline(second_prompt, true)
        if more_source.nil?
          source = nil
          break
        else
          source += (more_source + " ")
        end
      end
      source
    end

    def match_parenthesis(str)
      count = count_characters(str, ["(", ")"])
      count["("] == count[")"]
    end

    def count_characters(str, chars)
      count = chars.to_h{|ch| [ch, 0]}
      escaped = false
      in_string = false
      str.each_char { |rune|
        case rune
        when "\\"
          escaped = !escaped if in_string
        when '"'
          in_string = !in_string unless escaped
          escaped = false
        when *chars
          count[rune] += 1 unless in_string
        else
          escaped = false
        end
      }
      count
    end

  end                           # end of Repl
end
