require 'csv'
require 'yaml'
require 'tools/csv_formatter/shopifile'
require 'tools/csv_formatter/map/mapper'

module LeesToolbox

  def self.run(params)
    require 'tools/csv_formatter/uniteu'

    if params[:source_type] == "uniteu"
      $x = LeesToolbox::UniteU.new(params).parse
    elsif params[:source_type] == "rpro"
      $x = "RPro.new(params).parse"
    end
  end

  class CSV_Formatter

    attr_reader :source_file, :target_file, :verbose, :source, :data_type, :format, :products, :merge

    def initialize(params)

      @source_file = CSV.read(encode(params[:source]),:headers=>true,:header_converters=>:symbol)

      # Get target file
      @target_file = get_target_file({:source => params[:source], :target => params[:target]})

      # init empty products array
      @products = []

      @source_type = params[:source_type]
      @data_type = params[:data_type]
      @target_type = params[:target_type]
      @mapper = Mapper.new({:source_type=>@source_type, :data_type=>@data_type, :target_type=>@target_type})
    end

    def inspect
    end

    private

    def get_target_file(params)
      # If target_file is specified
      if !params[:target].nil?
        # If it doesn't contain a directory
        if File.dirname(params[:target]) == "."
          # put it in source_file base directory
          target_file_name = "#{File.dirname(File.absolute_path(params[:source]))}/#{params[:target]}"
        else
          target_file_name = File.absolute_path(params[:target])
        end
        # then check if the file exists
        if File.exist?(target_file_name)
          # mark @merge true and open existing file
          @merge = true
          @target_data = CSV.read(encode(target_file_name), :headers=>:true, :write_headers=>true, :skip_blanks=>true)
          target_file = CSV.open(target_file_name, "w")
        else
          # otherwise mark @merge false and create new file
          @merge = false
          target_file = CSV.open(target_file_name, "w")
        end
      else
        # if target_file is NOT specified
        # get directory of source file
        path = File.dirname(File.absolute_path(params[:source]))
        i = 1
        target_file = "#{path}/#{File.basename(params[:source],'.csv')}#{i}.csv"
        while File.exist?(target) == true
          i += 1
          target_file = "#{path}/#{File.basename(params[:source],'.csv')}#{i}.csv"
        end
        target_file = CSV.open(target, "w")
      end
      return target_file
    end

    def encode(file)
      begin
        encoded_file = File.open(file, "r", {:encoding => "UTF-8"})
      rescue
        encoded_file = File.open(file, "r", {:encoding => "Windows-1252:UTF-8"})
      end
      return encoded_file
    end


  end
end