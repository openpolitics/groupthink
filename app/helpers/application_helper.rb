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
  
  def state_image(state)
    case state
    when 'agree'
      "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/+1.png?v5' title='Agree'/>".html_safe
    when 'abstain'
      "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/hand.png?v5' title='Abstain'/>".html_safe
    when 'disagree'
      "<img src='https://github.global.ssl.fastly.net/images/icons/emoji/-1.png?v5' title='Disagree'/>".html_safe
    else
      ""
    end
  end

end
