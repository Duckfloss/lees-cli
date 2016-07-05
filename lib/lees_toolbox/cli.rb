require 'thor'
require 'abbrev'

module LeesToolbox
  class CLI < Thor
    include Thor::Actions

    class_option :v, :type=>:boolean, desc: "Run in chatty mode"

    # COMMAND: csv_formatter
    desc "csv [SOURCE]", "Convert a csv file from one format to another"
    option :target, :desc=>"Optional target file"
    def csv_formatter(source, *params)
      @source = check_csv(source)
      @params = get_csv_params(params)
      @params[:source] = @source
      
      $log = startlog

      require 'tools/csv_formatter'
      LeesToolbox.run(@params)
    end

    # COMMAND: images
    desc "images", "Batch format images for Lee's website"
    def images
      __method__.to_s
    end

    # COMMAND: ecimap
    desc "ecimap", "Convert product style data to RPro's ECImap"
    def ecimap
      __method__.to_s
    end

    # COMMAND: markdown
    desc "markdown", "Format product description text for Lee's website"
    def markdown
      __method__.to_s
    end

    # COMMAND: database
    desc "database", "This doesn't do anything yet"
    def database
      say "This doesn't do anything yet"
      exit 0
    end

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    map "md" => "markdown".to_sym
    map "db" => "database".to_sym

    private
    
    def get_csv_params(params)
      newparams = Hash.new

      # Check for command-line parameters
      params.each do |param|
        case param
          when /.csv$/
            newparams[:target] = param
          when "u", "r"
            newparams[:source_type] = param
          when "p", "v"
            newparams[:data_type] = param
          when "g", "d", "s"
            newparams[:target_type] = param
        end
      end
  
      # Ensure source type is r or u
      while !["r","u"].include? newparams[:source_type]
        newparams[:source_type] = ask "Where did this data come from:(r)pro or (u)niteu?"
      end

      # Try to guess data type by searching file name
      ["product","variant"].each do |i|
        if File.basename(@source).include? i
          newparams[:data_type] = i[0]
        end
      end

      # Ensure data type is p or v
      while !["p","v"].include? newparams[:data_type]
        newparams[:data_type] = ask "What type of data is is: (p)roducts or (v)ariants?"
      end

      # Ensure output format is s, d, or g
      while !["s","d","g"].include? newparams[:target_type]
        newparams[:target_type] = ask "What are you converting it to? (s)hopify, (d)ynalog, or (g)oogle?"
      end
      
      # Convert short params
      newparams.each do |k,p|
        case p
          when "u" then newparams[k] = "uniteu"
          when "r" then newparams[k] = "rpro"
          when "p" then newparams[k] = "products"
          when "v" then newparams[k] = "variants"
          when "g" then newparams[k] = "google"
          when "d" then newparams[k] = "dynalog"
          when "s" then newparams[k] = "shopify"
        end
      end

      return newparams
    end

    def check_csv(file)
      if !file.nil?
        if File.extname(file) != ".csv"
          say "#{file} is not a csv file"
          exit -1
        end
        if !File.exist?(file)
          if @source.nil?
            say "#{file} does not exist."
            exit -1
          end
        end
      end
      file
    end

    def startlog
      # If verbose is on, output messages to terminal
      if options[:v]
        log = Logger.new(STDOUT)
        log.formatter = proc do |severity, time, progname, msg|
          "#{msg}\n"
        end
      # Otherwise output messages to a log file
      else
        # Check for log directory in HOME
        Dir.mkdir("#{ENV['HOME']}/log") unless Dir.exist?("#{ENV['HOME']}/log")
        # Check for leestoolbox log file
        if File.exist?("#{ENV['HOME']}/log/leestoolbox-log.txt")
          # Check file size, rotate if over 50k
          if File.size("#{ENV['HOME']}/log/leestoolbox-log.txt") > 49999
            require 'fileutils'
            i = 1
            while File.exist? "#{ENV['HOME']}/log/leestoolbox-log#{i}.txt"
              i += 1
            end
            FileUtils.mv("#{ENV['HOME']}/log/leestoolbox-log.txt","#{ENV['HOME']}/log/leestoolbox-log#{i}.txt")
          end
        end
        log = Logger.new("#{ENV['HOME']}/log/leestoolbox-log.txt")
        log.formatter = proc do |severity, time, progname, msg|
          "#{time} - #{msg}\n"
        end
      end
      log
    end
  end

end
