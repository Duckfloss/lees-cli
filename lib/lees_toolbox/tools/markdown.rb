require 'csv'
require 'yaml'
require 'rchardet'
require 'htmlentities'

module LeesToolbox

  def self.run(params)
    md = Markdown.new(params)
    md.translate
  end

  class Markdown

    SPECIAL_CHARS = { "&acute;" => "'",
                      "&amp;" => "&",
                      "&apos;" => "'",
                      "&copy;" => "",
                      "&ldquo;" => '"',
                      "&lsquo;" => "'",
                      "&nbsp;" => " ",
                      "&ndash;" => "-",
                      "&mdash;" => "—",
                      "&rdquo;" => '"',
                      "&reg;" => "",
                      "&rsquo;" => "'",
                      "&trade;" => "",
                      "&quot;" => '"',
                      "&lt;" => "<",
                      "&gt;" => ">",
                      "&frac12;" => "1/2",
                      "&frac14;" => "1/4",
                      "&frac34;" => "3/4",
                      "&sup1;" => "1",
                      "&sup2;" => "2",
                      "&sup3;" => "3",
                      "\r\n" => "\n",
                      "\r" => "\n"
                      }

    def initialize(params)
      @type = params[:type]
      @file = params[:source]
      path = File.dirname(params[:source])
      filename = File.basename(params[:source],@type)
      @target = File.open("#{path}/#{filename}-FILTERED#{@type}", "w")
    end

    def translate
     # Detect file encoding
      if CharDet.detect(File.read(@file))["encoding"] != "UTF-8"
        encoding = "Windows-1252:UTF-8"
      else
        encoding = "UTF-8:UTF-8"
      end

      # Open file
      if @type == ".csv"
        # Header_converter proc
        nospaces = Proc.new{ |head| head.gsub(" ","_") }
        # Open with CSV
        file = CSV.open(@file, :headers => true, :header_converters => [:downcase, nospaces], :skip_blanks => true, :encoding => encoding)
      else
        file = File.open(@file, "r", :encoding => encoding)
      end

      output = parse(file)
      write_to_file(output)

    end

    private

    # METHOD: parse(file)
    # 
    def parse(file)
      if @type == ".csv"
        descriptions = get_descriptions(file)
        descriptions.each do |row|
          format(row)
        end
      else
        # Do it with text
      end
    end

    # METHOD: format
    # Divide text into sections and then filter
    def format(row)
      output = "<ECI>\n<div><font face='verdana'>\n"
      # Divide into hash of sections and
      # Format each section
      sections = sectionize(row).to_a.map! { |section| filter(section) }
#binding.pry

      # Wrap each section with a header and give it to output
      sections.each do |section|

      end
      output << "</font></div>"
    end

    # METHOD: filter(section)
    # Format section into HTML
    def filter(section)
      # section should be a paired array
      section[0] = section[0].split("#")
      head = section[0][0]
      rule = section[0][1]

      if head == "product_name"
        # product_name has but one format
        body = form_of_title(section[1])
      elsif head == "description"
        # description is always a graf
        body = form_of_graf(sanitize(section[1]))
      else
        # everything else is a list unless otherwise stated
        case rule
          when "graf"
            body = form_of_graf(sanitize(section[1]))
          when "table"
#binding.pry
            body = form_of_table(sanitize(section[1]))
          when "list"
            body = form_of_list(sanitize(section[1]))
          else
            body = form_of_list(sanitize(section[1]))
        end
      end
binding.pry
      [ head, body ]
    end
    
    # METHOD: form_of_graf(text)
    # Formats text block as a paragraph
    def form_of_graf(text)
      output = text.split("\n")
      output.map! do |line|
        line.strip!
        line.insert(0,"<p>")
        line.insert(-1,"</p>")
      end
      sanitize(output.join("\n"))
    end

    # METHOD: form_of_table(text)
    # Formats block of text as a table
    def form_of_table(text)
      output = "<table>"
      # Figure out what seperator is
      commas = text.scan(",").length
      tabs = text.scan("\t").length
      commas > tabs ? sep="," : sep="\t"  # Whichever is more is the seperator
      # Divide text into array of arrays
      table = text.split("\n").map! { |row| row.split(sep) }
#binding.pry


      output = sanitize(output)
    end

    # METHOD: form_of_list(text)
    # Formats block of text as a list
    def form_of_list(text)
      output = "<ul>\n"
      listdepth = 1
      # If there are dividers, remove "\n"s
      text.gsub!(/([:]) *\n+/,"\1 ")
      text = text.split("\n")
      # Wrap each line in <li>s
      text.each do |line|
        line.strip!
        # If line starts with *, sublist
        if line[0] == "*"
          line.sub!("*","\t<li style=\"list-style:none\"><strong>")
          output << "#{line}</strong>\n"
          output << "\t\t<ul>\n"
          listdepth += 1
        # If line starts with -, continue sublist
        elsif line[0] == "-"
          line.sub!("-","\t\t<li>")
          output << "#{line}</li>\n"
        else
          if listdepth > 1
            listdepth -= 1
            output << "\t\t</ul>\n\t</li>\n"
          end
          output << "\t<li>#{line}</li>\n"
        end
      end
      # If we get to end and haven't closed sublist, close it
      if listdepth > 1
        output << "\t\t</ul>\n\t</li>\n"
      end
      output << "</ul>"
      output = sanitize(output)
    end

    # METHOD: write_to_file(text)
    # write formatted text back to file
    def write_to_file(*text)
      if text
        @target << text
      end
      if !@target.closed?
        @target.close
      end
    end

    # METHOD: get_descriptions(data)
    # Returns array of descriptions
    def get_descriptions(data)
      # Get just the descriptions column
      # If :desc is present, that's it
      data = data.read
      headers = data.headers
      if headers.include?("desc")
        descriptions = data["desc"]
      else
        # Otherwise, ask which column to use
        header = ""
        while !headers.include?(header)
          puts "Which column has product descriptions?"
          headers.each { |h| puts "\t#{h}" }
          print "#: "
          header = gets.chomp
          descriptions = data[header]
        end
      end
      descriptions
    end

    # METHOD: sectionize(text)
    # Divide MD-formatted text into sections
    # Returns binary array
    def sectionize(text)
      sections = {}
      splits = text.split("{")
      splits.delete_at(0)
      splits.each do |splitted|
        part = splitted.split("}")
        sections[part[0]] = part[1]
      end
      sections
    end

    # METHOD: form_of_title(text)
    # Format text in title case
    def form_of_title(text)
      # Words we don't cap
      no_cap = ["a","an","the","with","and","but","or","on","in","at","to"]
      # Cycle through words
      title = text.split
      title.map! do |word|
        # First word is Vendor name - don't mess with it
        if word != title[0]
          # If asterisked or starts with a period, leave it alone
          if word[0] == "*"
            thisword = word.sub!("*","")
          # If it is a number leave it alone
          elsif word[0] =~ /[\.\d]/
            thisword = word
          # If there's a dash and the word's longer than 1 char
          elsif word.include?('-') && word.length > 1
            # Split at - and cap both sides
            thisword = word.split('-').each{|i| i.capitalize!}.join('-')
          # If in no_cap list, don't cap it
          elsif no_cap.include?(word.downcase)
            thisword = word.downcase
          # Otherwise, cap it
          else
            thisword = word.downcase.capitalize
          end
        else
          thisword = word
        end
        sanitize(thisword)
      end
      "<h2>#{title.join(' ')}<\h2>"
    end

    # METHOD: sanitize(input)
    # Replaces special characters with HTML
    def sanitize(input)
      # Convert special characters to HTML
      encoder = HTMLEntities.new(:html4)
      output = encoder.encode(input, :named)
      # Go back through and put some characters back
      SPECIAL_CHARS.each do |k,v|
        output.gsub!(k,v)
      end
      # Get rid of double returns
      while output.include?("\n\n")
        output.gsub!("\n\n","\n")
      end
      # get rid of double spaces
      while output.include?("  ")
        output.gsub!("  "," ")
      end
      output.strip
    end

=begin
# Converts the product description into a hash
# with the "product_name",
# "description", "features", and "specs"
def hashify(string)
  hash = Hash.new
  if string != nil
    string = string.split(/\n(?=\{)/)
    string.each do |section|
      hash[ ( section.slice(/[\w\d\_\#]+(?=\})/) ) ] = section[(section.index('}')+1)..-1].strip
    end
  end
  return hash
end

# encode special characters for HTML
def html_sanitizer(string, set=:basic)
  if set == :basic
    $htmlmap = MAPPINGS[:base]
  else
    $htmlmap = MAPPINGS[:base].merge!(MAPPINGS[:title])
  end

  string = string.split("")
  string.map! { |char|
    ( $htmlmap.has_key?(char.unpack('U')[0]) ) ? $htmlmap[char.unpack('U')[0]] : char
  }


  return string.join
end

# replace \r\n line endings with \n line endings
# check encoding, if not UTF-8, transcode
def file_sanitizer(file)
  file = File.open(file, mode="r+")
  content = File.read(file)
	content.force_encoding(Encoding::Windows_1252)
	content = content.encode!(Encoding::UTF_8, :universal_newline => true)
  content.gsub!("\r\n","\n")
  file.write(content)
end


# sanitize and capitalize
def product_name(string)
  string = html_sanitizer(title_case(string),:title)
end


# Make it a list
def listify(string)
  output = "<ul>\n"
  string.gsub!(/\:\n/, ":")
  arrayify = string.split("\n")
  arrayify.each do |line|
    line.strip!
    if line.length>0
      output << "\t<li>#{line}</li>\n"
    end
  end
  output << "</ul>\n"
end

# Make it segments
def segmentify(string)
  output = "<br>"
  array = string.split(/\n/)
  array.each do |x|
    if x.match(":")
      output << "#{x}<br>\n"
    else
      output << "<strong>#{x}</strong><br>\n"
    end
  end
  return output
end

# Make it a table
def tablify(string)
  output = "<table>\n"
  r = 0
  array = string.split(/\n/)
  array.each do |x|
    if !x.nil?
      output << "\t<tr>\n"
      x.gsub!("  ","\t")
      row = x.split(/\t/)
      row.each do |y|
        if r>0
          output << "\t\t<td>#{y}</td>\n"
        else
          output << "\t\t<th>#{y}</th>\n"
        end
      end
      output << "\t</tr>\n"
      r += 1
    end
  end
  output << "</table>\n\n"
  return output
end

# makes it a paragraph
def grafify(string)
  string.strip!
  string.gsub!("\n","<br>")
end


def format_section(string,format)
  string=html_sanitizer(string)
  case format
  when "table"
    string = tablify(string)
  when "seg"
    string = segmentify(string)
  when "graf"
    string = grafify(string)
  when "list" # is default
    string=listify(string)
  else
    string=listify(string)
  end
  return string
end


def formatify(string)
  output = ""
  product_data = hashify(string)
  temp_data = Hash.new
  product_data.each do |k,v|
    format = "" # marks what format to put section into
    if k.match("#")
      split = k.split("#")
      k = split[0]
      format = split[1]
    end

    case k #checks key
    when "product_name"
      temp_data[k]=product_name(v)
    when "description"
      temp_data[k] = "<p id=\"description\">#{html_sanitizer(v)}</p>\n"
    when "features"
      temp_data[k] = "<p id=\"features\">\n<u>Features</u>\n#{format_section(v,format)}\n</p>\n"
    when "specs"
      temp_data[k] = "<p id=\"specifications\">\n<u>Specifications</u>\n#{format_section(v,format)}\n</p>\n"
    end
  end
  output << body_format(temp_data)
  return output
end


def body_format(hash)
  product_name = hash["product_name"]
  description = hash["description"]
  features = hash["features"]
  specs = hash["specs"]

  body_format = "<ECI>\n<font face='verdana'>\n"
  body_format << "<h2 id=\"product_name\">#{hash['product_name']}</h2>\n"
  if hash.has_key? 'description'
    body_format << hash['description']
  end
  if hash.has_key? 'features'
    body_format << hash['features']
  end
  if hash.has_key? 'specs'
    body_format << hash['specs']
  end

  body_format << "</font>"

end
=end


  end
end