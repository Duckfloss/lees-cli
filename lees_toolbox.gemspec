$:.push File.expand_path("../lib", __FILE__)

require 'lees_toolbox/version'

Gem::Specification.new do |gem|
	gem.name = "lees-toolbox"
	gem.version = LeesToolbox::VERSION
	gem.author = "Duckfloss"

	gem.summary = "A command-line interface for Lee's scripts"
	gem.description = "This is a command-line interface for using all these dumb scripts and gems I use at work."
	gem.email = 'ben@bencjones.com'
	gem.homepage = 'https://github.com/Duckfloss/lees-toolbox'
	gem.license = 'MIT'

	gem.executables 	= ['lees-toolbox','ltool']

	gem.bindir		= 'bin'
	gem.require_path	= 'lib'

	gem.files			= Dir["{lib}/**/*.rb", "bin/*", "test/*"]

	gem.add_dependency("thor", "~> 0.18")
	gem.add_dependency("pry", ">= 0.9.12")
	gem.add_dependency("htmlentities", "~> 4.3")
	gem.add_dependency("rchardet", "~> 1.6")
	gem.add_dependency("rmagick", "~> 2.15")

	dev_dependencies = [['mocha', '>= 0.9.8'],
					  ['fakeweb'],
					  ['minitest', '~> 5.0'],
					  ['rake']
	]

	if gem.respond_to?(:add_development_dependency)
		dev_dependencies.each { |dep| gem.add_development_dependency(*dep) }
	else
		dev_dependencies.each { |dep| gem.add_dependency(*dep) }
	end

end
