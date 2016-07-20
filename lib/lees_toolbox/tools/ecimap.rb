require 'csv'
require 'inifile'
require 'fileutils'

module LeesToolbox

  def self.run(params)
    mapper = Eci_Map.new(params)
    mapper.map
  end

  class Eci_Map

    TEMP_PATH = ENV['HOME']
    ECI_PATH = "C:/DevKit/home/pos/testdata"
    ECILinkINI = "ECLink.INI"

    def initialize(params)
      @dir = params[:dir].downcase
      @source = params[:source]
      @csv = CSV.read(@source, :headers=>true,:skip_blanks=>false,:header_converters=>:symbol)
    end

    def map
      if @dir == "in"
        @eci_map = get_eci("#{ECI_PATH}/#{ECILinkINI}")
        in_it
      elsif @dir == "out"
        @eci_map = get_eci(copy_eci(TEMP_PATH))
      end
    end

    private

    # METHOD: Bring translations from ECI to local file
    def in_it
      # Make an array of unique "attr"s from @csv
      attrs = []
      @csv.each do |row|
        attrs << row[0]
      end
      attrs.uniq!

      # Make a dictionary from ECI
      dictionary = {}
      attrs.each do |attr|
        dictionary[attr] = @eci_map[attr]
      end

      # Open CSV and translate
      path=File.dirname(@source)
      name=File.basename(@source,".csv")
      newfile = "#{path}/#{name}copy.csv"
      CSV.open(newfile, 'w') do |csv_obj|
        csv_obj << ['Attr','Color']
        @csv.each do |row|
          pair = [ row[:attr], dictionary[row[:attr]].to_s ]
          csv_obj << pair
        end
      end
    end

    # METHOD: Get ECI's wordmapping dictionary
    def get_eci(ecilink)
      eci = IniFile.load(ecilink, :encoding=>'Windows-1252')
      wordmapping = eci['WordMapping']
      map = {}

      wordmapping.each do |k,v|
        if k.match /^ATTR/
          map[k.sub('ATTR<_as_>','')] = v
        end
      end
      map
    end

    # METHOD: Copy ECI's Ini file to temp directory
    # so's we don't break something
    def copy_eci(path)
      dupfile = "#{path}/#{ECILinkINI}backup"
      FileUtils.cp("#{ECI_PATH}/#{ECILinkINI}", dupfile)
      dupfile
    end

=begin
    def out_it
      # Copy eci file to temp dir
      temp_eci = copy_eci

      # Parse ECI file
      $wordmapping = get_eci(temp_eci)

      $wordmapping.merge!($map_hash) do |attr,oldcolor,newcolor|
        if oldcolor.nil?
          newcolor
        else
          oldcolor
        end
      end

      $wordmapping = $wordmapping.sort_by{|attr,color| attr.downcase}
      newwordmapping = {}
      $wordmapping.each do |attr,color|
        newwordmapping["ATTR<_as_>#{attr}"] = color
      end

      # Write eci to C:
      $eci['WordMapping'] = newwordmapping
      $eci.write

      # Backup eci file in R:
      FileUtils.cp("R:/RETAIL/RPRO/EC/ECLink.INI", "R:/RETAIL/RPRO/EC/ECLink.OLD")
      # Then copy temp_eci to R:
      FileUtils.cp("C:/Documents and Settings/pos/Desktop/Website/Toolbox/ECImap/data/ECLink.INI", "R:/RETAIL/RPRO/EC/ECLink.INI")

      exit 0
    end
=end
  end
end

class IniFile
  def write( opts = {} )
    filename = opts.fetch(:filename, @filename)
    @fn = filename unless filename.nil?
    File.open(@fn, 'w') do |f|
      @ini.each do |section,hash|
        f.puts "[#{section}]"
        hash.each {|param,val| f.puts "#{param}#{@param}#{escape_value val}"}
        f.puts
      end
    end
    self
  end
end

