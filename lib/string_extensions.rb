class String

  def contains_upvote?
    [
      ":thumbsup:",
      ":+1:",
      "👍",
    ].any? {|x| self.include?(x)}
  end

  def contains_downvote?
    [
      ":hand:",
      "✋",
    ].any? {|x| self.include?(x)}
  end

  def contains_block?
    [
      ":thumbsdown:",
      ":-1:",
      "👎",
    ].any? {|x| self.include?(x)}
  end

end