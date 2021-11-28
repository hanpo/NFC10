# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'

target 'NFC10' do

  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for NFC10

  pod 'MBProgressHUD'
  pod 'NVActivityIndicatorView'
  
end


post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = false;
    end
  end
end
