module ApplicationHelper
  
  def bootstrap_url
    ENV['BOOTSTRAP_CSS_URL'] || "//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css"
  end
  
  def new_session_path(_scope)
    new_user_session_path
  end

  def fa_sized_icon(icon, size = nil)
    if size
      icon += " #{size}"
    end
    fa_icon(icon)
  end
  
  @@state_style = {
    'waiting' => {
      class: 'warning',
      icon:  'clock-o',
    },
    'blocked' => {
      class: 'danger',
      icon:  'ban',
    },
    'rejected' => {
      class: 'danger',
      icon:  'ban',
    },
    'dead' => {
      class: 'danger',
      icon:  'ban',
    },
    'accepted' => {
      class: 'success',
      icon:  'check',
    },
    'passed' => {
      class: 'success',
      icon:  'check',
    },
    'agreed' => {
      class: 'success',
      icon:  'check',
    },
  }

  @@vote_style = {
    'yes' => {
      class: 'success',
      icon: 'check',
    },
    'no' => {
      class: 'warning',
      icon: 'times',
    },
    'block' => {
      class: 'danger',
      icon: 'ban',
    },
    'abstention' => {
      class: 'info',
      icon: 'meh-o',
    },
    'participating' => {
      class: 'default',
      icon: 'comments-o',
    },
  }

  def row_class(pr)
    @@state_style[pr.state][:class]
  end
  
  def user_row_class(state)
    @@vote_style[state][:class]
  end
  
  def vote_icon(vote, options = {})
    fa_sized_icon(@@vote_style[vote][:icon], options[:size])
  end

  def state_icon(state, options = {})
    fa_sized_icon(@@state_style[state][:icon], options[:size])
  end

end
