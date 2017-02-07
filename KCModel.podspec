Pod::Spec.new do |s|
  s.name         = 'KCModel'
  s.summary      = 'Personal model framework for iOS.'
  s.version      = '1.0.0'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.authors      = { 'koce' => 'koce.zhao@gmail.com' }
  s.social_media_url = 'http://www.jianshu.com/u/083bd990bfe2'
  s.homepage     = 'https://github.com/koce/KCModel'

  s.ios.deployment_target = '7.0'
  s.watchos.deployment_target = '2.0'

  s.source       = { :git => 'https://github.com/koce/KCModel.git', :tag => s.version.to_s }
  
  s.requires_arc = true
  s.source_files = 'KCModel/*.{h,m}'
  s.public_header_files = 'KCModel/*.{h}'
  
  s.frameworks = 'Foundation', 'CoreFoundation'

end