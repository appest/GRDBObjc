Pod::Spec.new do |s|
  s.name         = 'GRDBObjc'
  s.version      = '0.8'
  
  s.license      = { :type => 'MIT' }
  s.homepage     = 'https://github.com/groue/GRDBObjc'
  s.authors      = { 'Gwendal Roué' => 'gr@pierlis.com' }
  s.summary      = 'FMDB-compatible bindings to GRDB.swift.'
  s.source       = { :git => 'https://github.com/appest/GRDBObjc.git', :tag => "v#{s.version}" }
  s.module_name = 'GRDBObjc'
  
  s.swift_versions = ['4.2', '5']
  s.ios.deployment_target = '10.0'
  s.osx.deployment_target = '10.10'
  s.watchos.deployment_target = '2.0'
  
  s.source_files = 'Sources/GRDBObjc/*'
  s.dependency 'GRDBObjcCore', '0.8'
  s.framework = 'Foundation'
end
