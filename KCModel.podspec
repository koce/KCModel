Pod::Spec.new do |s|
  s.name         = ‘KCModel'
  s.summary      = 'High performance model framework for iOS/OSX.'
  s.version      = ‘1.0.0’
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { ‘koce’ => ‘koce.zhao@gmail.com' }
  s.social_media_url = 'http://www.jianshu.com/u/083bd990bfe2'
  s.homepage     = 'https://github.com/koce/KCModel'

  s.ios.deployment_target = ‘7.0’
  s.osx.deployment_target = '10.7'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.source       = { :git => 'https://github.com/koce/KCModel.git', :tag => s.version.to_s }
  
  s.requires_arc = true
  s.source_files = ‘KCModel/*.{h,m}'
  s.public_header_files = ‘KCModel/*.{h}'
  
  s.frameworks = 'Foundation', 'CoreFoundation'

end