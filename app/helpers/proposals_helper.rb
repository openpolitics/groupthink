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

  def calculate_diff(str)
    sections = [[:unchanged, ""]]
    last_type = :unchanged
    str.split("\n").map do |line|
      line_type = diff_line_type(line)
      if line_type == last_type
        sections.last[1] += "\n#{line[1..-1]}"
      elsif line_type
        last_type = line_type
        sections << [line_type, line[1..-1]]
      end
    end
    sections
  end

  def render_diff(str)
    return "" if str.nil?
    calculate_diff(str).map do |section|
      "<div class='diff #{section[0]}'>#{render_github_markdown(section[1]).strip}</div>"
    end.join
  end
end
