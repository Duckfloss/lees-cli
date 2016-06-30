require 'thor'
require 'abbrev'

module LeesToolbox
  class CLI < Thor
    include Thor::Actions

    class_option :v, :type=>:boolean,
                    :default=>false,
                    desc: "Run in chatty mode"

    desc "csv [SOURCE]", "Convert a csv file from one format to another"
    option :target, :desc=>"Optional target file"
    def csv(source, target=nil)
      @source = check_csv(source)
      @target = check_csv(target)

      params = get_csv_params

      puts "#{params[:s]} #{params[:d]} #{params[:t]}"
      puts "SOURCE is #{@source}\nTARGET is #{@target}\n"
    end

    desc "images", "Batch format images for Lee's website"
    def images
      __method__.to_s
    end

    desc "ecimap", "Convert product style data to RPro's ECImap"
    def ecimap
      __method__.to_s
    end

    desc "markdown", "Format product description text for Lee's website"
    def markdown
      __method__.to_s
    end

    desc "database", "This doesn't do anything yet"
    def database
      __method__.to_s
    end

    tasks.keys.abbrev.each do |shortcut, command|
      map shortcut => command.to_sym
    end

    map "md" => "markdown".to_sym
    map "db" => "database".to_sym

    private
    
    def get_csv_params
      params = {:s=>nil,:d=>nil,:t=>nil}

      # Ensure source type is r or u
      while !["r","u"].include? params[:s]
        params[:s] = ask "Where did this data come from:(r)pro or (u)niteu?"
      end

      # Try to guess data type by searching file name
      ["product","variant"].each do |i|
        if File.basename(@source).include? i
          params[:d] = i[0]
        end
      end

      # Ensure data type is p or v
      while !["p","v"].include? params[:d]
        params[:d] = ask "What type of data is is: (p)roducts or (v)ariants?"
      end

      # Ensure output format is s, d, or g
      while !["s","d","g"].include? params[:t]
        params[:t] = ask "What are you converting it to? (s)hopify, (d)ynalog, or (g)oogle?"
      end

      return params
    end

    def check_csv(file)
      if !file.nil?
        if File.extname(file) != ".csv"
          say "#{file} is not a csv file"
          exit -1
        end
        if !File.exist?(file)
          say "#{file} does not exist."
          exit -1
        end
      end
      file
    end
  end

end
