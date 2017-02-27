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
    when 'agree'
      'success'
    when 'abstain', 'participating'
      'warning'
    when 'disagree'
      'danger'
    else
      ''
    end
  end
  
  def vote_icon(vote)
    case vote
    when 'agree'
      fa_icon "thumbs-o-up"
    when 'abstain'
      fa_icon "hand-stop-o"
    when 'disagree'
      fa_icon "thumbs-o-down"
    else
      ""
    end
  end

  def state_icon(state)
    case state
    when 'waiting'
      fa_icon "clock-o"
    when 'blocked', 'rejected'
      fa_icon "ban"
    when 'accepted', 'passed', 'agreed'
      fa_icon "check"
    else
      ""
    end
  end

end
