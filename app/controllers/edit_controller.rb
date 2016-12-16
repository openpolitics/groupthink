class EditController < ApplicationController
  before_filter :get_parameters, except: :index
  before_filter :check_logged_in, except: :index
  
  extend Memoist

  def index
  end
  
  def edit    
    @content = get_files(original_repo_path, @filename)[@filename]
    @lineendings = detect_line_endings(@content)
  end

  def message
    # Prepare a fork if we don't have permission to push
    unless github.repository(original_repo_path).permissions.push
      github.fork original_repo_path
    end
  end
  
  def commit
    # Fix line endings
    @content = convert_line_endings(@content, @lineendings)
    if github.repository(original_repo_path).permissions.push
      new_branch = commit_file(original_repo_path, @filename, @content, @summary)
      @pr = open_pr(new_branch, @branch, @summary, @description)
    else
      new_branch = commit_file(user_repo_path, @filename, @content, @summary)
      @pr = open_pr("#{@current_user.username}:#{new_branch}", @branch, @summary, @description)
    end
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
    @filename = params[:filename] || params[:path]
    @format = @filename.split('.').last
    @content = params[:content]
    @summary = params[:summary]
    @description = params[:description]
    @lineendings = params[:lineendings]
  end

  def github
    @github = Octokit::Client.new(:access_token => session[:github_token])
  end

  def original_repo_path
    ENV['GITHUB_REPO']
  end
  
  def user_repo_path
    repo_name = ENV['GITHUB_REPO'].split("/").last
    "#{current_user.username}/#{repo_name}"
  end
  
  def branch
    params[:branch]
  end
  
  GITHUB_REPO_REGEX = /github.com[:\/]([^\/]*)\/([^\.]*)/

  def latest_commit(repo, branch_name)
    branch_data = github.branch repo, branch_name
    branch_data['commit']['sha']
  end
  memoize :latest_commit

  def tree(repo, branch)
    t = github.tree(repo, branch, :recursive => true)
  end
  memoize :tree

  def blob_shas(repo, branch, path)
    tree = tree(repo, branch).tree
    Hash[tree.select{|x| x[:path] =~ /^#{path}$/ && x[:type] == 'blob'}.map{|x| [x.path, x.sha]}]
  end
  memoize :blob_shas
  
  def blob_content(repo, sha)
    blob = github.blob repo, sha
    if blob['encoding'] == 'base64'
      Base64.decode64(blob['content'])
    else
      blob['content']
    end
  end
  memoize :blob_content
  

  def create_blob(repo, content)
    github.create_blob repo, content, "utf-8"
  end

  def add_blob_to_tree(repo, sha, filename)
    tree = tree repo, @branch
    new_tree = github.create_tree repo, [{
      path: filename,
      mode: "100644",
      type: "blob",
      sha: sha
    }], base_tree: tree.sha
    new_tree.sha
  end

  def get_files(repo, name)
    blobs = blob_shas(repo, @branch, name)
    Hash[blobs.map{|x| [x[0], blob_content(repo, x[1])]}]
  end

  def commit_sha(repo, sha, message)
    parent = latest_commit(repo, @branch)
    commit = github.create_commit repo, message, sha, [parent]
    commit.sha
  end
  
  def create_branch(repo, name, sha)
    branch = github.create_reference repo, "heads/#{name}", sha
    branch.ref
  end

  def open_pr(head, base, title, description)
    pr = github.create_pull_request original_repo_path, base, head, title, description
    pr.html_url
  end
  
  def commit_file(repo, name, content, message)    
    blob_sha = create_blob(repo, content)
    tree_sha = add_blob_to_tree(repo, blob_sha, name)
    commit_sha = commit_sha(repo, tree_sha, message)
    create_branch(repo, DateTime.now.to_s(:number), commit_sha)
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
