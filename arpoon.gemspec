Gem::Specification.new {|s|
	s.name         = 'arpoon'
	s.version      = '0.0.1'
	s.author       = 'meh.'
	s.email        = 'meh@paranoici.org'
	s.homepage     = 'http://github.com/meh/arpoon'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'ARP changes reporting daemon, can be used to protect against spoofing.'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_dependency 'bitmap'
	s.add_dependency 'hwaddr'
	s.add_dependency 'pcaprub'
}
