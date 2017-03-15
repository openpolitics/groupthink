module ApplicationHelper
  
  def bootstrap_url
    ENV['BOOTSTRAP_CSS_URL'] || "//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css"
  end
  
  def new_session_path(_scope)
    new_user_session_path
  end

  def row_class(pr)
    {
      'waiting'  => 'warning',
      'blocked'  => 'danger',
      'rejected' => 'danger',
      'dead'     => 'danger',
      'accepted' => 'success',
      'passed'   => 'success',
      'agreed'   => 'success',
    }[pr.state]
  end
  
  def user_row_class(state)
    {
      'yes'           => 'success',
      'no'            => 'warning',
      'block'         => 'danger',
      'participating' => 'default'
    }[state]
  end
  
  def fa_sized_icon(icon, size = nil)
    icon += " #{size}" if size
    fa_icon(icon)
  end
  
  def vote_icon(vote, options = {})
    icon = {
      "yes"           => "check",
      "no"            => "times",
      "block"         => "ban",
      "participating" => "comments-o"
    }[vote]
    fa_sized_icon(icon, options[:size])
  end

  def state_icon(state, options = {})
    icon = {
      'waiting'  => 'clock-o',
      'blocked'  => 'ban',
      'rejected' => 'ban',
      'dead'     => 'ban',
      'accepted' => 'check',
      'passed'   => 'check',
      'agreed'   => 'check',
    }[state]
    fa_sized_icon(icon, options[:size])
  end

end
