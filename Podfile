# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'
use_modular_headers!
inhibit_all_warnings!

target 'MyKTGG' do
  # Comment the next line if you don't want to use dynamic frameworks
  #use_frameworks!
  pod 'Firebase/Analytics'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Messaging'
  pod 'GoogleSignIn'
  pod 'FacebookLogin'
end

post_install do |pi|
  pi.pods_project.targets.each do |t|
    t.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
