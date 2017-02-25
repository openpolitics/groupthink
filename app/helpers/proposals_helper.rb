module ProposalsHelper

  def render_github_markdown(markdown)
    auto_link(GitHub::Markup.render('comment.markdown', markdown).html_safe)
  end

end