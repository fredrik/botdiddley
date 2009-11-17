class UntweetFormatter
  # ['anna','klas','sven']
  # => ["@anna, @klas and @sven have stopped following you."]
  def format_messages(names=[])
    return [] if names.empty?
    return ["@#{names[0]} has stopped following you."] if names.length == 1

    and_that_guy = ["and @"+names.pop]
    them = names.map {|name| "@"+name }.join(", ")
    return ["#{them} #{and_that_guy} have stopped following you."]
  end
end
