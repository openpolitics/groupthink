# frozen_string_literal: true

#
# Allow users to propose new changes.
#
class EditController < ApplicationController
  before_action :get_parameters, except: :index
  before_action :check_logged_in, except: :index

  extend Memoist
  GITHUB_REPO_REGEX = /github.com[:\/]([^\/]*)\/([^\.]*)/

  def index
  end

  def new
    @content = ""
  end

  def edit
    @content = get_files(original_repo_path, @filename)[@filename]
    @lineendings = detect_line_endings(@content)
  end

  def message
    # Prepend title if we have been given one, for a new filename
    if @title.present?
      @content = "---\ntitle: #{@title}\n---\n#{@content}"
    end
    # Prepare a fork if we don't have permission to push
    unless github.repository(original_repo_path).permissions.push
      github.fork original_repo_path
    end
  end

  def commit
    # Fix line endings
    @content = convert_line_endings(@content, @lineendings)
    # Do we need to work in a fork?
    forked = !github.repository(original_repo_path).permissions.push
    repo_path = forked ? user_repo_path : original_repo_path
    # Get the SHA of the edited branch - this is the head we want to add to
    base_sha = github.tree(original_repo_path, @branch, recursive: true).sha
    # What shall we call our new branch?
    branch_name = Time.now.to_s(:number)
    # Update fork if appropriate by making a new branch from the upstream base SHA
    # We do this even if not forking, as there's no harm in doing so
    create_branch(repo_path, branch_name, base_sha)
    # Commit the file on our new branch
    new_branch = commit_file(repo_path, @filename, @content, @summary, base_sha, branch_name)
    # open PR
    pull_from = forked ? "#{@current_user.login}:#{new_branch}" : branch_name
    @pr = open_pr(pull_from, @branch, @summary, @description)
    # Check for CLA
    @cla_url = "https://www.clahub.com/agreements/#{original_repo_path}"
    r = Faraday.get @cla_url
    @has_cla = (r.status == 200)
  end

  private

    def check_logged_in
      unless user_signed_in?
        session[:original_path] = request.path
        redirect_to action: :index
      end
    end

    def get_parameters
      @owner = params[:owner]
      @repo = params[:repo]
      @branch = params[:branch]
      @title = params[:title]
      @filename = params[:filename] || params[:path]
      @format = params[:format] || (@filename ? @filename.split(".").last : "md")
      if @title.present? && @filename.nil?
        @filename = @title.parameterize + ".#{@format}"
      end
      @content = params[:content]
      @summary = params[:summary]
      @description = params[:description]
      @lineendings = params[:lineendings] || :crlf
    end

    def github
      @github ||= Octokit::Client.new(access_token: session[:github_token])
    end

    def original_repo_path
      ENV["GITHUB_REPO"]
    end

    def user_repo_path
      repo_name = ENV["GITHUB_REPO"].split("/").last
      "#{current_user.login}/#{repo_name}"
    end

    def branch
      params[:branch]
    end


    def latest_commit(repo, branch_name)
      branch_data = github.branch repo, branch_name
      branch_data["commit"]["sha"]
    end
    memoize :latest_commit

    def tree(repo, branch)
      github.tree(repo, branch, recursive: true)
    end
    memoize :tree

    def blob_shas(repo, branch, path)
      tree = tree(repo, branch).tree
      Hash[tree.select do |x|
        x[:path] =~ /^#{path}$/ && x[:type] == "blob"
      end.map { |x| [x.path, x.sha] }]
    end
    memoize :blob_shas

    def blob_content(repo, sha)
      blob = github.blob repo, sha
      if blob["encoding"] == "base64"
        Base64.decode64(blob["content"])
      else
        blob["content"]
      end
    end
    memoize :blob_content


    def create_blob(repo, content)
      github.create_blob repo, content, "utf-8"
    end

    def add_blob_to_tree(repo, blob_sha, filename, base_sha)
      new_tree = github.create_tree repo, [{
        path: filename,
        mode: "100644",
        type: "blob",
        sha: blob_sha
      }], base_tree: base_sha
      new_tree.sha
    end

    def get_files(repo, name)
      blobs = blob_shas(repo, @branch, name)
      Hash[blobs.map { |x| [x[0], blob_content(repo, x[1])] }]
    end

    def commit_sha(repo, sha, message, parent_sha)
      commit = github.create_commit repo, message, sha, parent_sha
      commit.sha
    end

    def create_branch(repo, name, sha)
      branch = github.create_reference repo, "heads/#{name}", sha
      branch.ref
    end

    def update_branch(repo, name, sha)
      branch = github.update_reference repo, "heads/#{name}", sha
      branch.ref
    end

    def open_pr(head, base, title, description)
      pr = github.create_pull_request original_repo_path, base, head, title, description
      Proposal.find_or_create_by!(
        number: pr.number,
        opened_at: Time.now,
        title: title,
        proposer: @current_user
      )
    end

    def commit_file(repo, name, content, message, base_sha, branch_name)
      blob_sha = create_blob(repo, content)
      tree_sha = add_blob_to_tree(repo, blob_sha, name, base_sha)
      commit_sha = commit_sha(repo, tree_sha, message, base_sha)
      update_branch(repo, branch_name, commit_sha)
    end

    def detect_line_endings(str)
      case str
      when /\r\n/
        :crlf
      when /\r/
        :cr
      when /\n/
        :lf
      else
        nil
      end
    end

    def convert_line_endings(str, lineendings)
      case lineendings.to_sym
      when :cr
        str.gsub("\r\n", "\r")
      when :lf
        str.gsub("\r\n", "\n")
      else
        str
      end
    end
end
