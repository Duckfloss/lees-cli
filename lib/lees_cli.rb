require 'thor'
require 'abbrev'
require 'yaml'

module LeesCLI
  class CLI < Thor
    include Thor::Actions

    desc "csv", "??"
    def csv
      puts "csv"
    end

    desc "images", "???"
    def images
      puts "images"
    end

    desc "ecimap", "????"
    def ecimap
      puts "ecimap"
    end

    desc "markdown", "?????"
    def markdown
      puts "markdown"
    end

    desc "database", "This doesn't do anything yet"
    def database
      puts "database"
    end

    shortcuts = tasks.keys.abbrev
    shortcuts.merge!({"md"=>"markdown","db"=>"database"})
    shortcuts.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    private

  end
end
