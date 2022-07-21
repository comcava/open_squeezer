#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint native_opencv.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'native_opencv'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter plugin project.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # telling CocoaPods not to remove framework
  s.preserve_paths = 'opencv2.framework' 
  # telling linker to include opencv2 framework
  s.xcconfig = { 'OTHER_LDFLAGS' => '-framework opencv2' } 
  # including OpenCV framework
  s.vendored_frameworks = 'opencv2.framework'
  # including native framework
  s.frameworks = 'AVFoundation' 

  s.preserve_paths = 'libheif/**'
  s.xcconfig = {
      # 'HEADER_SEARCH_PATHS' => "\"${PODS_ROOT}/libheif/libheif\""
      'HEADER_SEARCH_PATHS' => "\"libheif/libheif\""
  }
  s.subspec 'libheif' do |ss|
    ss.dependency 'libheif/libheif'
    ss.source_files = 'libheif/libheif/**/*', 'heif.h'
  end

  s.public_header_files = "libheif/libheif/heif.h"

  # including C++ library
  s.library = 'c++'

end
