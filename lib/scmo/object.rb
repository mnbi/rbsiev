# frozen_string_literal: true

require "singleton"

module Scmo

  class Object
    class << self
      protected :new
    end

    def boolean?;   false; end
    def pair?;      false; end
    def symbol?;    false; end
    def number?;    false; end
    def char?;      false; end
    def string?;    false; end
    def vector?;    false; end
    def port?;      false; end
    def procedure?; false; end
    def null?;      false; end
    def list?;      false; end

    def to_rb
      true
    end

    def to_s
      ""
    end

    class Boolean < Object
      class << self
        protected :new
      end

      def boolean?; true; end
    end
  end

  class EmptyList < Object
    include Singleton

    def null?; true; end
    def list?; true; end

    def to_rb
      []
    end

    def to_s
      "()"
    end
  end

  EMPTY_LIST = EmptyList.instance

  class UndefValue < Object
    include Singleton

    def to_rb
      nil
    end

    def to_s
      "#<undef>"
    end
  end

  UNDEF = UndefValue.instance

  class FalseValue < Object::Boolean
    include Singleton

    def to_rb
      false
    end

    def to_s
      "#f"
    end
  end

  class TrueValue < Object::Boolean
    include Singleton

    def to_rb
      true
    end

    def to_s
      "#t"
    end
  end

  FALSE = FalseValue.instance
  TRUE = TrueValue.instance

  def self.scheme_object?(obj)
    obj.kind_of?(Object)
  end

  def self.rbo2scmo(rb_obj)
    case rb_obj
    when FalseClass
      FALSE
    when TrueClass
      TRUE
    when NilClass
      EMPTY_LIST
    when Array
      rb_obj.empty? ? EMPTY_LIST : List.list(*rb_obj)
    else
      rb_obj
    end
  end
end
