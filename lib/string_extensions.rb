# frozen_string_literal: true


#
# Additions to built-in String class to make it easy to check for cast votes.
#
class String
  #
  # Does the string contain a "yes" vote?
  # Checks for ✅ and 👍 symbols, and old-style github emoji code equivalents
  #
  # @return [boolean] True if the string contains a yes vote
  #
  def contains_yes?
    [
      ":white_check_mark:",
      "✅",
      ":thumbsup:",
      ":+1:",
      "👍",
    ].any? { |x| self.include?(x) }
  end

  #
  # Does the string contain a "no" vote?
  # Checks for ❎ and ✋ symbols, and old-style github emoji code equivalents
  #
  # @return [boolean] True if the string contains a no vote
  #
  def contains_no?
    [
      ":negative_squared_cross_mark:",
      "❎",
      ":hand:",
      "✋",
    ].any? { |x| self.include?(x) }
  end

  #
  # Does the string contain an abstention?
  # Checks for 🤐, and old-style github emoji code equivalent
  #
  # @return [boolean] True if the string contains an abstention
  #
  def contains_abstention?
    [
      ":zipper_mouth_face:",
      "🤐",
    ].any? { |x| self.include?(x) }
  end

  #
  # Does the string contain an "block" vote?
  # Checks for 🚫 and 👎, and old-style github emoji code equivalent
  #
  # @return [boolean] True if the string contains an block vote
  #
  def contains_block?
    [
      ":no_entry_sign:",
      "🚫",
      ":thumbsdown:",
      ":-1:",
      "👎",
    ].any? { |x| self.include?(x) }
  end
end
