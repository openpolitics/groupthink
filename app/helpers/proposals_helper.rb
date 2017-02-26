module ProposalsHelper

  def render_github_markdown(markdown)
    markdown = replace_emoji(markdown)
    markdown = GitHub::Markup.render('comment.markdown', markdown).html_safe
    markdown = auto_link(markdown)
  end

  def replace_emoji(markdown)
    {
      ":thumbsup:" => "👍",
      ":thumbsdown:" => "👎",
      ":+1:" => "👍",
      ":-1:" => "👎",
      ":hand:" => "✋",
    }.each_pair do |before, after|
      markdown = markdown.gsub(before, after)
    end
    markdown
  end

end