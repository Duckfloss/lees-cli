require 'csv'
require 'inifile'
require 'fileutils'

module LeesToolbox

  def self.run(params)
    mapper = Eci_Map.new(params)
    mapper.map
  end

  class Eci_Map

    ECI_PATH = "R:/RETAIL/RPRO/EC"
    ECILinkINI = "ECLink.INI"

    def initialize(params)
      @dir = params[:dir].downcase
      @source = params[:source]
      @csv = CSV.read(@source, :headers=>true,:skip_blanks=>false,:header_converters=>:symbol)
      @eci_map = get_eci("#{ECI_PATH}/#{ECILinkINI}")
    end

    def map
      if @dir == "in"
        in_it
      elsif @dir == "out"
        out_it
      end
    end

    private

    # METHOD: Bring translations from ECI to local file
    def in_it
      # Make an array of unique "attr"s from @csv
      attrs = []
      @csv.each do |row|
        attrs << row[:attr]
      end
      attrs.uniq!

      # Make a dictionary from ECI
      dictionary = {}
      attrs.each do |attr|
        dictionary[attr] = @eci_map["ATTR<_as_>#{attr}"]
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

    # METHOD: Get a hash of ECI's wordmapping dictionary
    def get_eci(ecilink)
      eci = IniFile.load(ecilink, :encoding=>'Windows-1252')
      wordmapping = eci['WordMapping']
    end

    # METHOD: Backup ECI's Ini file just in case
    def backup_eci(path)
      dupfile = "#{path}/#{ECILinkINI}backup"
      FileUtils.cp("#{ECI_PATH}/#{ECILinkINI}", dupfile)
      dupfile
    end

    # METHOD: Send translations from local file to ECI
    def out_it
      # Get :attr index
      attr = @csv.headers.index(:attr)
      # Get color column selector
      if @csv.headers.include?(:colors)     # Try :colors
        selector = @csv.headers.index(:colors)
      elsif @csv.headers.include?(:color)   # Try :color
        selector = @csv.headers.index(:color)
      else                                  # Else grab column after :attr
        selector = attr+1
      end
      # Make a dictionary from CSV
      dictionary = {}
      @csv.to_a.uniq.drop(1).each do |row|
        dictionary["ATTR<_as_>#{row[attr]}"] = row[selector]
      end

      # Merge dictionary into ECI
      @eci_map.merge!(dictionary)

      # Alphabetize
      @eci_map = @eci_map.sort_by{ |k,v| k }

      # Backup ECI file
      backup_eci(ECI_PATH)

      # Write @eci_map to ECI file
      ecifile = IniFile.load("#{ECI_PATH}/#{ECILinkINI}", :encoding=>'Windows-1252')
      ecifile['WordMapping'] = @eci_map
      ecifile.write
    end
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

