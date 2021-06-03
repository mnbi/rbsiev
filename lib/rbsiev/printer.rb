# frozen_string_literal: true

module Rbsiev
  class Printer
    def initialize
      @verbose = false
    end

    attr_accessor :verbose

    def print(value)
      if @verbose
        pp verbose
      end
      puts value.to_s
    end

  end
end
