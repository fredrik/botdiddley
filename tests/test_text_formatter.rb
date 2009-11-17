require 'helper'
require 'text_formatter'

class TestTextFormatter < Test::Unit::TestCase
  def setup
    @t = TextFormatter.new
  end
  def test_format_messages

    # format_messages() accepts a list of names,
    # returns a list of messages formatted to fit inside 140 characters.
    
    assert_equal [], @t.format_messages([])
    assert_equal ["@james has stopped following you."],
      @t.format_messages(['james'])
    assert_equal ["@anna, @klas and @sven have stopped following you."],
      @t.format_messages(['anna','klas','sven'])
  end
end