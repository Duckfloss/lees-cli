class Shopifile

  attr_accessor :data, :source, :type, :product

  def initialize(datarow, params)
    @data = datarow
    @source = params[:source]
    @data_type = params[:data_type]
    @map = params[:map]
    @product = {}
  end


  def process
    @map.each do |head,field|
      @product[head] = sanitize(head.to_sym,field.to_sym)
    end
    return @product
  end

  private

  def sanitize(head,field)
    case head
      when :pf_id then return @data[field]
      when :handle then return @data[field].gsub(" ","_")
      when :title then return @data[field]
      when :body then return body_filter(@data[field])
      when :option1_name then return @data[field]
      when :option2_name then return @data[field]
      when :option1_value then return @data[field]
      when :option2_value then return @data[field]
      when :variant_sku then return @data[field]
      when :variant_inventory_qty then return @data[field]
      when :variant_price then return @data[field]
    end
  end

  def body_filter(data)
    data
  end

  def vendor_filter(data)
    vendors = YAML.load(File.open("./lib/formatcsv/vendors.yml"))
  end
end
