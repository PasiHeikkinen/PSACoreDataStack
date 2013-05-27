Pod::Spec.new do |s|
  s.name = 'PSACoreDataStack'
  s.version = '0.0.7'
  s.license = 'MIT'
  s.summary = 'Reusable Core Data stack.'
  s.homepage = 'https://github.com/PasiHeikkinen/PSACoreDataStack'
  s.authors = { 'Pasi Heikkinen' => 'pasi.heikkinen@pencilsamurai.com'}
  s.source = { :git => 'https://github.com/PasiHeikkinen/PSACoreDataStack.git', :tag => '0.0.7'}
  s.source_files = 'PSACoreDataStack'
  s.requires_arc = true
  
  s.osx.deployment_target = '10.8'
  s.osx.frameworks = 'CoreData'
end