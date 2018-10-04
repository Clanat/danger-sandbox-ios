require_relative 'helper/changelog_helper.rb'

default_platform :ios

platform :ios do

  before_all do |lane, options|
    Actions.lane_context[SharedValues::FFREEZING] = options[:ffreezing]
    skip_docs
  end

  after_all do |lane|
    clean_build_artifacts
  end

  error do |lane, exception|
    clean_build_artifacts
    rsb_remove_release_branch
  end

  ### LANES

  lane :rsb_fabric do |options|
    rsb_fabric_private(
      crashlytics_groups: [ENV['CRASHLYTICS_GROUP']]
    )
  end

  lane :rsb_testflight do |options|
    rsb_testflight_private(
      skip_submission: true
    )
  end

  lane :rsb_fabric_testflight do |options|
    rsb_fabric_testflight_private(
      crashlytics_groups: [ENV['CRASHLYTICS_GROUP']],
      skip_submission: true
    )
  end

  lane :rsb_add_devices do
    file_path = prompt(
      text: 'Enter the file path: '
    )

    register_devices(
      devices_file: file_path
    )
  end

  lane :ci do
    if rsb_possible_to_trigger_ci_build?
      rsb_trigger_ci_fastlane
    else
      UI.user_error!('You need to configure CI environments: CI_APP_TOKEN, CI_APP_NAME, CI_JENKINS_USER, CI_JENKINS_USER_TOKEN')
    end
  end

  lane :rsb_changelog do |options|
    ready_tickets = rsb_search_jira_tickets(
      statuses: [rsb_jira_status[:ready]]
    )
    changelog_release_notes = rsb_changelog_release_notes(ready_tickets)
    rsb_gen_changelog(release_notes: changelog_release_notes)
  end

  lane :rsb_post_to_slack do |options|
    ready_tickets = rsb_search_jira_tickets(
      statuses: [rsb_jira_status[:ready]]
    )
    slack_release_notes = rsb_slack_release_notes(ready_tickets)
    rsb_post_to_slack_channel(
      configuration: ENV['CONFIGURATION_ADHOC'],
      release_notes: slack_release_notes,
      destination: "Fabric"
    )
  end

  ### PRIVATE LANES

  private_lane :rsb_fabric_private do |options|

    if is_ci?
      setup_jenkins
    end

    ensure_git_status_clean

    rsb_git_pull
    rsb_start_release_branch(
      testflight_build: false
    )

    rsb_run_tests_if_needed
    rsb_stash_save_tests_output
    
    ready_tickets = rsb_search_jira_tickets(
      statuses: [rsb_jira_status[:ready]]
    )
    fabric_release_notes = rsb_jira_tickets_description(ready_tickets)
    slack_release_notes = rsb_slack_release_notes(ready_tickets)
    changelog_release_notes = rsb_changelog_release_notes(ready_tickets)

    rsb_stash_pop_tests_output
    rsb_commit_tests_output
    rsb_update_display_name_with_clean
    rsb_update_provisioning_profiles(
      type: :adhoc
    )
    rsb_build_and_archive(
      configuration: ENV['CONFIGURATION_ADHOC']
    )
    rsb_send_to_crashlytics(
      groups: options[:crashlytics_groups],
      notes: fabric_release_notes
    )

    rsb_move_jira_tickets(
      tickets: ready_tickets,
      status: rsb_jira_status[:test_build]
    )
    rsb_post_to_slack_channel(
      configuration: ENV['CONFIGURATION_ADHOC'],
      release_notes: slack_release_notes,
      destination: "Fabric"
    )
    if is_ci?
      reset_git_repo(force: true, exclude: ['Carthage/Build', 'Carthage/Checkouts'])
    end

    rsb_gen_changelog(release_notes: changelog_release_notes)
    rsb_commit_changelog_changes
    rsb_update_build_number
    rsb_commit_build_number_changes
    rsb_end_release_branch
  end

  private_lane :rsb_testflight_private do |options|
    precheck_if_needed
    check_no_debug_code_if_needed

    if is_ci?
      setup_jenkins
    end

    ensure_git_status_clean

    rsb_git_pull
    rsb_start_release_branch(
      testflight_build: true
    )

    rsb_run_tests_if_needed
    rsb_stash_save_tests_output
    
    rsb_stash_pop_tests_output
    rsb_commit_tests_output
    rsb_update_display_name_with_clean
    rsb_update_provisioning_profiles(
      type: :appstore
    )
    configuration = ENV['CONFIGURATION_APPSTORE']
    rsb_build_and_archive(
      configuration: configuration
    )
    rsb_send_to_testflight(
      skip_submission: options[:skip_submission]
    )
    rsb_post_to_slack_channel(
      configuration: configuration,
      destination: "Testflight"
    )

    if is_ci?
      reset_git_repo(force: true, exclude: ['Carthage/Build', 'Carthage/Checkouts'])
    end

    ready_tickets = rsb_search_jira_tickets(
      statuses: [rsb_jira_status[:ready]]
    )
    changelog_release_notes = rsb_changelog_release_notes(ready_tickets)
    rsb_gen_changelog(release_notes: changelog_release_notes)
    rsb_commit_changelog_changes

    rsb_update_build_number
    rsb_commit_build_number_changes
    rsb_end_release_branch
  end

  private_lane :rsb_fabric_testflight_private do |options|
    precheck_if_needed
    check_no_debug_code_if_needed

    if is_ci?
      setup_jenkins
    end

    ensure_git_status_clean

    rsb_git_pull
    rsb_start_release_branch(
      testflight_build: true
    )

    rsb_run_tests_if_needed
    rsb_stash_save_tests_output

    ready_tickets = rsb_search_jira_tickets(
      statuses: [rsb_jira_status[:ready]]
    )
    fabric_release_notes = rsb_jira_tickets_description(ready_tickets)
    slack_release_notes = rsb_slack_release_notes(ready_tickets)
    changelog_release_notes = rsb_changelog_release_notes(ready_tickets)

    rsb_stash_pop_tests_output
    rsb_commit_tests_output
    rsb_update_display_name_with_clean
    rsb_update_provisioning_profiles(
      type: :adhoc
    )
    rsb_build_and_archive(
      configuration: ENV['CONFIGURATION_ADHOC']
    )    
    rsb_send_to_crashlytics(
      groups: options[:crashlytics_groups],
      notes: fabric_release_notes
    )

    rsb_move_jira_tickets(
      tickets: ready_tickets,
      status: rsb_jira_status[:test_build]
    )
    rsb_post_to_slack_channel(
      configuration: ENV['CONFIGURATION_ADHOC'],
      release_notes: slack_release_notes,
      destination: "Fabric"
    )
    
    clean_build_artifacts
    rsb_update_provisioning_profiles(
      type: :appstore
    )
    rsb_build_and_archive(
      configuration: ENV['CONFIGURATION_APPSTORE']
    )
    rsb_send_to_testflight(
      skip_submission: options[:skip_submission]
    )
    rsb_post_to_slack_channel(
      configuration: ENV['CONFIGURATION_APPSTORE'],
      destination: "Testflight"
    )
    
    if is_ci?
      reset_git_repo(force: true, exclude: ['Carthage/Build', 'Carthage/Checkouts'])
    end

    rsb_gen_changelog(release_notes: changelog_release_notes)
    rsb_commit_changelog_changes

    rsb_update_build_number
    rsb_commit_build_number_changes
    rsb_end_release_branch
  end

  private_lane :rsb_build_and_archive do |options|
    configuration = options[:configuration]
    rsb_update_extensions_build_and_version_numbers_according_to_main_app

    if configuration == ENV['CONFIGURATION_ADHOC']
      gym(    
        configuration: configuration,
        include_bitcode: false,
        export_options: {
            uploadBitcode: false,
            uploadSymbols: true,
            compileBitcode: false
        }
      )
    else
      gym(configuration: configuration) 
    end
  end

  private_lane :rsb_send_to_crashlytics do |options|
    crashlytics(
      groups: options[:groups],
      notes: options[:notes]
    )
  end

  private_lane :rsb_send_to_testflight do |options|
    pilot(
      ipa: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
      skip_submission: options[:skip_submission],
      skip_waiting_for_build_processing: true
    )
  end
end

module SharedValues
  FFREEZING = :FFREEZING  
end

def ffreezing? 
  Actions.lane_context[SharedValues::FFREEZING] == true
end

def precheck_if_needed
  precheck(app_identifier: ENV['BUNDLE_ID']) if ENV['NEED_PRECHECK'] == 'true'
end

def check_no_debug_code_if_needed    
  ensure_no_debug_code(text: 'TODO|FIXME', path: 'Classes/', extension: '.swift') if ENV['CHECK_DEBUG_CODE'] == 'true'
end
