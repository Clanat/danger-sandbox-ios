private_lane :rsb_trigger_ci_fastlane do

  app_token = ENV['CI_APP_TOKEN']
  app_name = ENV['CI_APP_NAME']  
  jenkins_user = ENV['CI_JENKINS_USER']
  jenkins_user_token = ENV['CI_JENKINS_USER_TOKEN']
  base_url = ENV['CI_URL']
  if base_url.nil?
      base_url = 'cis.local:8080'
  end

  sh('git checkout develop')
  sh('git pull')
  sh('git push')

  url = 'http://' + jenkins_user + ':' + jenkins_user_token + '@' + base_url + '/job/' + app_name + '/build?token=' + app_token
  sh('curl -X GET ' + '"' + url + '"')
end

def rsb_possible_to_trigger_ci_build?
  ENV['CI_APP_TOKEN'] && ENV['CI_APP_NAME'] && !is_ci?
end