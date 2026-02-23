#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint zoom.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_zoom'
  s.version          = '0.0.2'
  s.summary          = 'A new flutter plugin project.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  # TODO: Set `homepage` to your repo URL.
  s.screenshots = 'https://admhomolapp.com21.com.br/frontend/public/images/logo-principal-pt-br.png', 'https://www.groupsoftware.com.br/wp-content/themes/site-2020/images/marca-group.svg'
  s.social_media_url = 'https://www.facebook.com/groupsoftware'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Com21 Software' => 'lucasmartins.m.25@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '16.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -framework MobileRTC -framework zoomcml -framework MobileRTCScreenShare',
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES' => 'YES'
  }
  s.swift_version = '5.0'
  
  # Zoom Meeting SDK dependencies
  s.frameworks = [
    'AVFoundation',
    'AudioToolbox',
    'CoreGraphics',
    'CoreMedia',
    'CoreVideo',
    'ReplayKit',
    'VideoToolbox',
    'Security',
    'SystemConfiguration',
    'UIKit',
  ]
  s.libraries = 'c++'

  s.preserve_paths = 'MobileRTC.xcframework', 'MobileRTCScreenShare.xcframework', 'zoomcml.xcframework', 'MobileRTCResources.bundle'
  s.vendored_frameworks = 'MobileRTC.xcframework', 'MobileRTCScreenShare.xcframework', 'zoomcml.xcframework'
  s.resource = 'MobileRTCResources.bundle'
end
