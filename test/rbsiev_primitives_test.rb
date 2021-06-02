# frozen_string_literal: true

require "test_helper"

class RbsievPrimitivesTest < Minitest::Test
  def test_it_has_the_names_map
    refute_nil Rbsiev::PRIMITIVE_NAMES_MAP
  end

  def test_it_renames_some_primitives
    { "+" => :add, "-" => :subtract, "=" => :same_value? }.each { |name, sym|
      assert_equal Rbsiev::PRIMITIVE_NAMES_MAP[name], sym
    }
  end
end
