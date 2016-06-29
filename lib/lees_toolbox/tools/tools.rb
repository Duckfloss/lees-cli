

Dir.chdir File.dirname(__FILE__) do
  Dir.foreach Dir.pwd do |entry|
    if Dir.exist?(entry) && entry != "." && entry != ".."
      require "#{File.absolute_path(entry)}/#{entry}.rb"
    end
  end
end

#binding.pry


