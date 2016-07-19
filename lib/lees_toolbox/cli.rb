require 'thor'
require 'abbrev'

module LeesToolbox
  class CLI < Thor
    include Thor::Actions

    class_option :verbose, :aliases=>"-v", :type=>:boolean, desc: "Run in chatty mode"

    # COMMAND: csv_formatter
    desc "csv [SOURCE]", "Convert a csv file from one format to another"
    option :target, :desc=>"Optional target file"
    def csv(source, *params)
      @source = check_file(source, ext="csv")
      @params = get_csv_params(params)
      @params[:source] = @source

      $log = startlog
      require 'tools/csv_formatter'
      LeesToolbox.run(@params)
    end

    # COMMAND: images
    desc "images", "Batch format images for Lee's website"
    option :eci, :aliases=>"-e", :default=>false, :type=>:boolean,
           :desc=>"Convert to eci image directory"
    option :source, :aliases=>"-s", :type=>:string,
           :desc=>"Source image or directory",
           :default=>"C:/Documents and Settings/pos/My Documents/Downloads/WebAssets"
    option :dest, :aliases=>"-d", :type=>:string,
           :desc=>"Directory to output images to",
           :default=>"R:/RETAIL/IMAGES/4Web"
    option :format, :aliases=>"-f", :type=>:array,
           :desc=>"List of sizes to convert to",
           :default=>["sw","med","lg"]
    def images
      @params = {}
      @params[:format] = get_format(options[:format])
      if !options[:source].nil?
        if options[:source] =~ /\.[A-Za-z]{3,4}$/
          @params[:source] = check_file(options[:source], nil, "file")
        else
          @params[:source] = check_file(options[:source] ,nil, "dir")
        end
      end
      if !options[:dest].nil?
        @params[:dest] = check_file(options[:dest] ,nil, "dir")
      end
      @params[:eci] = options[:eci]

      $log = startlog
      require 'tools/images'
      LeesToolbox.run(@params)
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

    # Shortcuts
    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end
    map "md" => "markdown".to_sym
    map "db" => "database".to_sym

    private

    # METHOD: Ensure submitted formats are allowed
    def get_format(formats)
      format = []
      formats.each do |k,v|
        allowed_formats = ["thumb","swatch","medium","large"].abbrev
        allowed_formats["lg"] = "large"
        if !allowed_formats[k].nil?
          format << allowed_formats[k]
        else
          say "#{k} is not a valid image size. Please select th, sm, med, or lg"
          exit -1
        end
      end
      return format
    end

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

    # METHOD: Check file or dir to see if it exists and is the right format
    # Exit on failure
    # Return file or dir name on success
    def check_file(file, ext=nil, type="file")
      if type == "file"
        if !ext.nil?
          if File.extname(file) != ".#{ext}"
            say "#{file} should be formatted as #{ext}"
            exit -1
          end
        end
        if !File.exist?(file)
          say "The file named \"#{file}\" does not exist."
          exit -1
        end
      else type == "dir"
        if !Dir.exist?(file)
          say "The file named \"#{file}\" does not exist."
          exit -1
        end
      end
      file
    end

    #METHOD: Starts logging, outputs to console if verbose is true
    def startlog
      # If verbose is on, output messages to terminal
      if options[:verbose]
        require 'io/console'
        log = Logger.new(STDOUT)
        log.level = Logger::INFO
        log.formatter = proc do |severity, time, progname, msg|
          "#{msg}\n"
        end
      # Otherwise output messages to a log file
      else
      # Check for log directory in HOME
        Dir.mkdir("#{ENV['HOME']}/log") unless Dir.exist?("#{ENV['HOME']}/log")
        log = Logger.new("#{ENV['HOME']}/log/leestoolbox-log.txt", shift_age = 7, shift_size = 65536)
        log.formatter = proc do |severity, time, progname, msg|
          "#{time} - #{msg}\n"
        end
      end
      log
    end
  end
end
