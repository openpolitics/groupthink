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

  def replace_emoji(str)
    [
      [":white_check_mark:", "✅"],
      [":negative_squared_cross_mark:", "❎"],
      [":no_entry_sign:", "🚫"],
      [":thumbsup:", "👍"],
      [":thumbsdown:", "👎"],
      [":+1:", "👍"],
      [":-1:", "👎"],
      [":hand:", "✋"],
      [":smiley:", "😃"],
    ].each do |replacement|
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

  def render_diff(str)
    return "" if str.nil?
    sections = [[:unchanged, ""]]
    last_type = " "
    str.split("\n").map do |line|
      if line.starts_with?("@")
        next
      end
      if line.starts_with?(last_type)
        sections.last[1] += "\n#{line[1..-1]}"
      else
        types = {
          "+": :added,
          "-": :removed,
          " ": :unchanged
        }
        last_type = line[0]
        sections << [types[line[0].to_sym], line[1..-1]]
      end
    end
    sections.map do |section|
      "<div class='diff #{section[0]}'>#{render_github_markdown(section[1])}</div>"
    end.join
  end
end
