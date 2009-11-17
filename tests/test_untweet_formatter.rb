require 'helper'
require 'untweet_formatter'

class TestUntweetFormatter < Test::Unit::TestCase
  def test_format_messages
    # format_messages() accepts a list of names,
    # returns a list of messages formatted to fit inside 140 characters.
    assert_equal [], UntweetFormatter.format_messages([])
    assert_equal ["@james has stopped following you."],
      UntweetFormatter.format_messages(['james'])
    assert_equal ["@anna, @klas and @sven have stopped following you."],
      UntweetFormatter.format_messages(['anna','klas','sven'])
  end
end
