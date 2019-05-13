# frozen_string_literal: true

#
# Helper methods for Proposal views
#
module ProposalsHelper
  def render_github_markdown(markdown)
    markdown = replace_emoji(markdown)
    markdown = GitHub::Markup.render("comment.markdown", markdown).html_safe
    markdown = link_usernames(markdown)
    markdown = link_proposals(markdown)
    auto_link(markdown)
  end

  EMOJI_REPLACEMENTS = [
    [":white_check_mark:", "✅"],
    [":negative_squared_cross_mark:", "❎"],
    [":no_entry_sign:", "🚫"],
    [":thumbsup:", "👍"],
    [":thumbsdown:", "👎"],
    [":+1:", "👍"],
    [":-1:", "👎"],
    [":hand:", "✋"],
    [":smiley:", "😃"],
  ]

  def replace_emoji(str)
    EMOJI_REPLACEMENTS.each do |replacement|
      str = str.gsub(replacement[0], replacement[1])
    end
    str
  end

  def link_usernames(str)
    str.scan(/(\s|^|\>)@(\w+)/).each do |match|
      str = str.gsub "@#{match[1]}", "<a href='/users/#{match[1]}'>@#{match[1]}</a>"
    end
    str.html_safe
  end

  def link_proposals(str)
    str.scan(/(\s|^|\>)#(\d+)/).each do |match|
      str = str.gsub "##{match[1]}", "<a href='/proposals/#{match[1]}'>##{match[1]}</a>"
    end
    str.html_safe
  end

  def ignore_diff_line?(line)
    ["@", "---", "+++"].any? do |prefix|
      line.starts_with?(prefix)
    end
  end

  def diff_line_type(line)
    # Ignore some lines completely
    return nil if ignore_diff_line?(line)
    # Detect type
    {
      "+": :added,
      "-": :removed,
      " ": :unchanged
    }[line[0].to_sym]
  end

  def parse_diff_line(line)
    line_type = diff_line_type(line)
    line_type ? [line_type, line[1..-1]] : nil
  end

  def chunk_diff(diff)
    # Parse all lines
    lines = [[:unchanged, ""]]
    lines += diff.split("\n").map { |line| parse_diff_line(line) }.compact
    # Detect groups where the line type changes
    grouped_lines = lines.slice_when { |before, after| before[0] != after[0] }
    # Merge grouped lines into a single chunk
    grouped_lines.map { |x| [x[0][0], x.map { |y| y[1] }.join("\n")] }
  end

  def render_diff(diff)
    return "" if diff.nil?
    chunk_diff(diff).map do |section|
      "<div class='diff #{section[0]}'>#{render_github_markdown(section[1]).strip}</div>"
    end.join
  end
end
