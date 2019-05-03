# frozen_string_literal: true

#
# Common view helper methods
#
module ApplicationHelper
  def bootstrap_url
    ENV.fetch("BOOTSTRAP_CSS_URL", "//maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css")
  end

  def new_session_path(_scope)
    new_user_session_path
  end

  def fa_sized_icon(icon, size)
    if size
      icon += " #{size}"
    end
    fa_icon(icon)
  end

  STATE_STYLE = {
    waiting: {
      class: "warning",
      icon:  "clock-o",
    },
    blocked: {
      class: "danger",
      icon:  "ban",
    },
    rejected: {
      class: "danger",
      icon:  "ban",
    },
    dead: {
      class: "danger",
      icon:  "ban",
    },
    accepted: {
      class: "success",
      icon:  "check",
    },
    passed: {
      class: "success",
      icon:  "check",
    },
    agreed: {
      class: "success",
      icon:  "check",
    },
  }

  VOTE_STYLE = {
    yes: {
      class: "success",
      icon: "check",
    },
    no: {
      class: "warning",
      icon: "times",
    },
    block: {
      class: "danger",
      icon: "ban",
    },
    abstention: {
      class: "info",
      icon: "meh-o",
    },
    participating: {
      class: "default",
      icon: "comments-o",
    },
  }

  def row_class(pr)
    STATE_STYLE[pr.state.to_sym][:class]
  end

  def user_row_class(state)
    VOTE_STYLE[state.to_sym][:class]
  end

  def vote_icon(vote, size: nil)
    fa_sized_icon(VOTE_STYLE[vote.to_sym][:icon], size)
  end

  def state_icon(state, size: nil)
    fa_sized_icon(STATE_STYLE[state.to_sym][:icon], size)
  end
end
