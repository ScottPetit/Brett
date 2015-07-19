Pod::Spec.new do |spec|
  spec.name = 'Brett'
  spec.version = '1.0.1'
  spec.authors = {'Scott Petit' => 'petit.scott@gmail.com'}
  spec.homepage = 'https://github.com/ScottPetit/Brett'
  spec.summary = 'Untar tar files.'
  spec.source = {:git => 'https://github.com/ScottPetit/Brett.git', :tag => "v#{spec.version}"}
  spec.license = { :type => 'MIT', :file => 'LICENSE' }
  spec.platform = :ios, '6.0'
  spec.requires_arc = true
  spec.frameworks = 'Foundation'
  spec.library = 'z'
  spec.source_files = 'Brett/*.{h,m}'
end
