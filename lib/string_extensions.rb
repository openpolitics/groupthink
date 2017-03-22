class String

  def contains_yes?
    [
      ":white_check_mark:",
      "✅",
      ":thumbsup:",
      ":+1:",
      "👍",
    ].any? {|x| self.include?(x)}
  end

  def contains_no?
    [
      ":negative_squared_cross_mark:",
      "❎",
      ":hand:",
      "✋",
    ].any? {|x| self.include?(x)}
  end

  def contains_abstain?
    [
      ":zipper_mouth_face:",
      "🤐",
    ].any? {|x| self.include?(x)}
  end

  def contains_block?
    [
      ":no_entry_sign:",
      "🚫",
      ":thumbsdown:",
      ":-1:",
      "👎",
    ].any? {|x| self.include?(x)}
  end

end