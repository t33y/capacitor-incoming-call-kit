Pod::Spec.new do |s|
    s.name             = 'WebRTCFramework'
    s.version          = '1.0.0'
    s.summary          = 'WebRTC XCFramework'
    s.description      = 'WebRTC compiled as XCFramework for iOS'
    s.homepage         = 'https://webrtc.org'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'You' => 'you@example.com' }
    s.platform         = :ios, '12.0'
    s.source           = { :path => '.' }
    s.vendored_frameworks = 'WebRTC.xcframework'
  end