#
#  Be sure to run `pod spec lint zeroth.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "zeroth-private"
  s.version      = "0.1.0"
  s.summary      = "Zeroth Speech-To-Text (STT) library for iOS"
  s.description  = <<-DESC
Zeroth was initially developed as part of Atlas’s Conversational AI platform, which enables enterprises to add analysis and intelligence to their conversational data.
We now introduce Zeroth Cloud as a hosted service for any developer to incorporate speech-to-text into his or her service.
We'd love to hear from you! Please email us at support@goodatlas.com  with any questions, suggestions or requests.
                   DESC

  s.homepage     = "https://zeroth-cloud.goodatlas.com"
  s.license      = { :type => 'Apache License', :file => 'LICENSE' }
  s.author       = { "Bryan S. Kim" => "seulkee@gmail.com" }
  s.source       = { :git => "https://github.com/seulkee/zeroth-client-ios.git", :tag => "#{s.version}" }
  s.ios.deployment_target = '10.0'
  s.source_files  = "Zeroth-iOS/Zeroth - STT library/*.{h,m}"
  #s.exclude_files = "Jetfire - websocket/Exclude"

  # s.public_header_files = "Classes/**/*.h"
  s.dependency "jetfire", "~> 0.1.5"

end
