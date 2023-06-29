#
# Be sure to run `pod lib lint GrubPaySDK.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GrubPaySDK'
  s.version          = '0.1.0'
  s.summary          = 'GrubPay.io SDK for embedding card/ACH payment UI'
  s.swift_version    = '4.2'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  GrubPay.io SDK for embedding card/ACH payment UI
  Providing both UIView element and modal style
                       DESC

  s.homepage         = 'https://github.com/iotpayca/GrubPaySDK-IOS'
  s.screenshots      = 'https://raw.githubusercontent.com/iotpayca/GrubPaySDK-IOS/master/ScreenShots/ach.png', 'https://raw.githubusercontent.com/iotpayca/GrubPaySDK-IOS/master/ScreenShots/card.png'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Edward Yuan' => 'edward.yuan@iotpay.ca' }
  s.source           = { :git => 'https://github.com/iotpayca/GrubPaySDK-IOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'Sources/GrubPaySDK/Classes/**/*'
  s.resources = ['Sources/GrubPaySDK/Assets/*.png', 'Sources/GrubPaySDK/Resources/*.lproj']
  

  s.frameworks = 'UIKit', 'VisionKit'

end
