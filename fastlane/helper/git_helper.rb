require_relative '../helper/string_exts_helper.rb'

def remote_branch_exists?(branch)
  result = `git branch -a | egrep 'remotes/origin/#{branch}' |  wc -l`  
  result.strip.to_bool
end

def rsb_git_pull
  if is_ci? == true
    sh('git checkout develop')
  end
  sh('git pull')
end