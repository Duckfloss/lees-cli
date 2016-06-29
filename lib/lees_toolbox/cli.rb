require 'thor'
require 'abbrev'
require 'yaml'

module LeesToolbox
  class CLI < Thor
    include Thor::Actions

    desc "csv", "??"
    def csv
      __method__.to_s
    end

    desc "images", "???"
    def images
      __method__.to_s
    end

    desc "ecimap", "????"
    def ecimap
      __method__.to_s
    end

    desc "markdown", "?????"
    def markdown
      __method__.to_s
    end

    desc "database", "This doesn't do anything yet"
    def database
      __method__.to_s
    end

    desc "-v", "Run in chatty mode"
    option :verbose, :type => :boolean
    def _v
      __method__.to_s
    end

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    map "md" => "markdown".to_sym
    map "db" => "database".to_sym

    private

  end
end
