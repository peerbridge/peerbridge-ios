platform :ios, '14.0'

target 'peerbridge-ios' do
  use_frameworks!

  pod 'SwiftyRSA'
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
end

target 'peerbridge-ios-tests' do
  use_frameworks!

  pod 'SwiftyRSA'
  pod 'SwiftLint'
  pod 'SQLite.swift', '~> 0.12.0'
  pod 'Firebase/Analytics'
  pod 'Firebase/Messaging'
end


# NOTE: Since Xcode 12, we need to manually raise the deployment
# target of any pods that are below the minimum supported iOS 9.0,
# otherwise we will get compiler warnings for all of these pods.
# See https://github.com/cocoapods/cocoapods/issues/9884
post_install do |pi|
   pi.pods_project.targets.each do |t|
       t.build_configurations.each do |bc|
           if bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] == '8.0'
             bc.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
           end
       end
   end
end
