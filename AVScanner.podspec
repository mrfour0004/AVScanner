#
# Be sure to run `pod lib lint AVScanner.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AVScanner'
  s.version          = '1.0.0'
  s.summary          = 'A 1D/2D barcode reader based on AVFoundation.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

#  s.description      = <<-DESC
#
#                       DESC

  s.homepage         = 'https://github.com/mrfour0004/AVScanner'
  # s.screenshots    = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mrfour' => 'mrfour0004@outlook.com' }
  s.source           = { :git => 'https://github.com/mrfour0004/AVScanner.git', :tag => "#{s.version}" }
  # s.social_media_url = 'https://twitter.com/mrfour0004

  s.ios.deployment_target = '10.0'

  s.source_files = 'Sources/**/*'
  s.swift_versions = ['5.1']
  
  # s.resource_bundles = {
  #   'AVScanner' => ['AVScanner/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
