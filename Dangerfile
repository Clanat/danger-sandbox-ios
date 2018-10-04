
# Constants
DEV_BRANCH = 'develop'
MAX_LINES_OF_CODE = 500

# Base branch
unless github.branch_for_base == DEV_BRANCH
  failure 'Development branch is not selected as base branch' 
end

# Big pull request
if git.lines_of_code > MAX_LINES_OF_CODE
  failure 'PR is too big'
end

# Labels
if github.pr_labels.empty?
  failure 'PR label is missing, please set `wip` or `ready` label' 
end

# Merge status
unless github.pr_json['mergeable']
  warn('This PR cannot be merged yet.', sticky: false)
end

# Swiftlint
swiftlint.config_file = '.swiftlint.yml'
swiftlint.lint_files
