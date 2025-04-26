Pod::Spec.new do |s|
    s.name             = 'WebRTCFramework'
    s.version          = '134.0.0'
    s.summary          = 'WebRTC XCFramework'
    s.description      = 'WebRTC compiled as XCFramework for iOS'
    s.homepage         = 'https://webrtc.org'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'stasel' => 'github.com/stasel/WebRTC.git' }
    s.platform         = :ios, '13.0'
    s.source           = { :path => '.' }
    s.vendored_frameworks = 'WebRTC.xcframework'
  end
  