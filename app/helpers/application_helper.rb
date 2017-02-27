module ApplicationHelper
  
  def new_session_path(scope)
      new_user_session_path
  end
    
  def row_class(pr)
    case pr.state
    when 'passed', 'agreed', 'accepted'
      'success'
    when 'waiting'
      'warning'
    when 'blocked', 'dead', 'rejected'
      'danger'
    end
  end
  
  def user_row_class(state)
    case state
    when 'yes'
      'success'
    when 'no'
      'warning'
    when 'block'
      'danger'
    when 'participating'
      'default'
    end
  end
  
  def vote_icon(vote, options = {})
    icon = ""
    case vote
    when 'yes'
      icon = "thumbs-o-up"
    when 'no'
      icon = "hand-stop-o"
    when 'block'
      icon = "thumbs-o-down"
    when 'participating'
      icon = "comments-o"
    end
    icon += " #{options[:size]}" if options[:size]
    icon.blank? ? nil : fa_icon(icon)
  end

  def state_icon(state, options = {})
    icon = ""
    case state
    when 'waiting'
      icon = "clock-o"
    when 'blocked', 'rejected'
      icon = "ban"
    when 'accepted', 'passed', 'agreed'
      icon = "check"
    end
    icon += " #{options[:size]}" if options[:size]
    icon.blank? ? nil : fa_icon(icon)
  end

end
