#binding.pry

require 'csv'
module LeesToolbox
  class CSVConverter

  #We're just gonna ask about these in shell
=begin
  desc "-s", "Source format: (r)pro or (u)niteu"
    option :s, :type=>:string, :required=>true
    def _s(source_format)
      source_format
    end

    desc "-d", "Data type: (p)roducts or (v)ariants"
    option :d, :type=>:string, :required=>true
    def _d(data_type)
      data_type
    end

    desc "-t", "Target format: (g)oogle, (s)hopify, or (d)ynalog"
    option :t, :type=>:string, :required=>true
    def _t(target_format)
      target_format
    end

=end
  end
end