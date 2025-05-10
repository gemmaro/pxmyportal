# frozen_string_literal: true

require "test_helper"

class PxmyportalTest < Test::Unit::TestCase
  test "VERSION" do
    assert do
      ::Pxmyportal.const_defined?(:VERSION)
    end
  end

  test "something useful" do
    assert_equal("expected", "actual")
  end
end
