$:.push File.expand_path("../lib", __FILE__)

require 'lees_cli/version'

Gem::Specification.new do |gem|
	gem.name = "lees-cli"
	gem.version = LeesCLI::VERSION
	gem.author = "Duckfloss"

	gem.summary = "A command-line interface for Lee's scripts"
	gem.description = "This is a command-line interface for using all these dumb scripts and gems I use at work."
	gem.email = 'ben@bencjones.com'
	gem.homepage = 'https://github.com/Duckfloss/lees-cli'
	gem.license = 'MIT'

	gem.executables 	= ['lees-cli','lcli']

	gem.bindir		= 'bin'
	gem.require_path	= 'lib'

	gem.files			= Dir["{lib}/**/*.rb", "bin/*", "test/*"]

	gem.add_dependency("activemodel", ">= 4.2.2")
	gem.add_dependency("activesupport", ">= 4.2.2")
	gem.add_dependency("thor", "~> 0.18.1")
	gem.add_dependency("pry", ">= 0.9.12.6")

	dev_dependencies = [['mocha', '>= 0.9.8'],
					  ['fakeweb'],
					  ['minitest', '~> 5.0'],
					  ['rake']
	]

	if s.respond_to?(:add_development_dependency)
		dev_dependencies.each { |dep| s.add_development_dependency(*dep) }
	else
		dev_dependencies.each { |dep| s.add_dependency(*dep) }
	end

end
