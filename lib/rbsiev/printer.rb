# frozen_string_literal: true

module Rbsiev
  class Printer
    def initialize
      @verbose = false
    end

    attr_accessor :verbose

    def print(value)
      pp value
    end

  end
end
