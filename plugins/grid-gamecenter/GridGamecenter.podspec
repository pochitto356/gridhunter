Pod::Spec.new do |s|
  s.name = 'GridGamecenter'
  s.version = '1.0.0'
  s.summary = 'Game Center plugin for GRID HUNTER'
  s.license = 'Proprietary'
  s.homepage = 'https://github.com/pochitto356/gridhunter'
  s.author = 'pochitto games'
  s.source = { :git => 'https://github.com/pochitto356/gridhunter.git', :tag => s.version.to_s }
  s.source_files = 'ios/Plugin/**/*.{swift,h,m}'
  s.ios.deployment_target = '14.0'
  s.dependency 'Capacitor'
  s.frameworks = 'GameKit'
  s.swift_version = '5.1'
end
