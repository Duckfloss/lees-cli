require 'thor'
require 'abbrev'

module LeesToolbox
  class CLI < Thor
    include Thor::Actions

    class_option :v, :type=>:boolean, desc: "Run in chatty mode"

    # COMMAND: csv
    desc "csv [SOURCE]", "Convert a csv file from one format to another"
    option :target, :desc=>"Optional target file"
    def csv(source, *params)
      @source = check_csv(source)
      @params = get_csv_params(params)
      @params[:source] = @source

      require 'tools/csv'
      LeesToolbox::CSV.new(@params)
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
      newparams = {:target=>nil,:s=>nil,:d=>nil,:t=>nil}

      # Check for command-line parameters
      params.each do |param|
        case param
          when /.csv$/
            newparams[:target] = param
          when "u", "r"
            newparams[:s] = param
          when "p", "v"
            newparams[:d] = param
          when "g", "d", "s"
            newparams[:t] = param
        end
      end
  
      # Ensure source type is r or u
      while !["r","u"].include? newparams[:s]
        newparams[:s] = ask "Where did this data come from:(r)pro or (u)niteu?"
      end

      # Try to guess data type by searching file name
      ["product","variant"].each do |i|
        if File.basename(@source).include? i
          newparams[:d] = i[0]
        end
      end

      # Ensure data type is p or v
      while !["p","v"].include? newparams[:d]
        newparams[:d] = ask "What type of data is is: (p)roducts or (v)ariants?"
      end

      # Ensure output format is s, d, or g
      while !["s","d","g"].include? newparams[:t]
        newparams[:t] = ask "What are you converting it to? (s)hopify, (d)ynalog, or (g)oogle?"
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

  end

end
