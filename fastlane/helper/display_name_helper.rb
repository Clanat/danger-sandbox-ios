require_relative 'plist_helper.rb'

# Updating bundle display name.
private_lane :rsb_update_display_name_with_clean do
  next unless bundle_name != bundle_display_name
  
  plist_path = ENV['INFOPLIST_PATH']
  set_info_plist_value(
    path: plist_path,
    key: 'CFBundleDisplayName',
    value: bundle_name
  )

  sh("git commit -a -m 'Clean the build number from the display name'")
end