module ProposalsHelper

  def render_github_markdown(markdown)
    markdown = replace_emoji(markdown)
    markdown = GitHub::Markup.render('comment.markdown', markdown).html_safe
    markdown = link_usernames(markdown)
    markdown = link_proposals(markdown)
    markdown = auto_link(markdown)
  end

  def replace_emoji(str)
    {
      ":white_check_mark:" => "✅",
      ":negative_squared_cross_mark:" => "❎",
      ":no_entry_sign:" => "🚫",
      ":thumbsup:" => "👍",
      ":thumbsdown:" => "👎",
      ":+1:" => "👍",
      ":-1:" => "👎",
      ":hand:" => "✋",
      ":smiley:" => "😃",
    }.each_pair do |before, after|
      str = str.gsub(before, after)
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

end