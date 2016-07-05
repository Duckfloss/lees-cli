class Mapper

  attr_reader :map, :headers

  def initialize(params)
    file = YAML.load(File.open("lib/lees_toolbox/tools/csv_formatter/map/#{params[:target_type]}.yml"))
    @map = file["#{params[:source_type]}_#{params[:data_type]}"]
    @headers = file["headers"].split
  end

end