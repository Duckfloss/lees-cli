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
      @target = "#{path}/#{filename}-FILTERED#{@type}"
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
        data = CSV.open(@file, :headers => true, :header_converters => [:downcase, nospaces], :skip_blanks => true, :encoding => encoding)
      else
        data = File.open(@file, "r", :encoding => encoding)
      end

      output = parse(data)
      write_to_file(output)
    end

    private

    # METHOD: parse(data)
    # 
    def parse(data)
      if @type == ".csv"
        output = ["Desc"]
        descriptions = get_descriptions(data)
        descriptions.each do |row|
          output << format(row)
        end
      elsif @type == ".txt"
        output = format(data.read)
      end
      output
    end

    # METHOD: write_to_file(text)
    # write formatted text back to file
    def write_to_file(data)
      if @type == ".csv"
        CSV.open(@target, "w", :encoding => "UTF-8", :headers => true) do |csv|
          data.each do |row|
            csv << [row]
          end
        end
      else
        File.open(@target, "w", :encoding => "UTF-8") do |file|
          file << data
        end
      end
    end

    # METHOD: format
    # Divide text into sections and then filter
    def format(text)
      output = "<ECI>\n<div><font face='verdana'>\n"
      # Divide into hash of sections and
      # Format each section
      sections = sectionize(text).to_a.map! { |section| filter(section) }

      # Wrap each section with a div and give it to output
      sections.each do |section|
        header = section[0]=="product_name" ? "" : "\t<u>#{section[0].capitalize!}</u>\n"
        output << "<div id=\"#{section[0]}\">\n"
        output << header
        output << "\t#{section[1]}\n"
        output << "</div>\n"
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
        body = form_of_graf(section[1])
      else
        # everything else is a list unless otherwise stated
        case rule
          when "graf"
            body = form_of_graf(section[1])
          when "table"
            body = form_of_table(section[1])
          when "list"
            body = form_of_list(section[1])
          else
            body = form_of_list(section[1])
        end
      end
      [ head, body ]
    end
    
    # METHOD: form_of_graf(text)
    # Formats text block as a paragraph
    def form_of_graf(text)
      text = sanitize(text)
      output = text.split("\n")
      output.map! do |line|
        line.strip!
        line.insert(0,"<p>")
        line.insert(-1,"</p>")
      end
      output.join("\n")
    end

    # METHOD: form_of_table(text)
    # Formats block of text as a table
    def form_of_table(text)
      text.gsub!(/\r\n/,"\n")                       # Clean up newlines
      # Figure out what seperator is
      commas = text.scan(",").length
      tabs = text.scan("\t").length
      commas > tabs ? sep="," : text.gsub!("\t","|"); sep="|"   # Whichever is more is the seperator
      text.strip!                                   # Now take out white space
      table = text.split("\n").map! { |row| row.split(sep) }    # Divide text into array of arrays
      rows = table.length                           # Count rows and columns
      columns = 0
      table.each do |row|
        row.length > columns ? columns = row.length : columns
      end
      output = "<table>\n"
      r = 1 # Row counter
      table.each do |row|                           # Now build table
        if row.join.length < 1 then next end        # If row is empty then skip
        output << "\t<tr>\n"                        # Start row
        c = 0                                       # Column counter
        colspan = row.length < columns ? columns-row.length+1 : false  # Do we need colspan?
        code = r==1 ? "th" : "td"                   # HTML cell code
        row.each do |field|
          c += 1
          output << "\t\t<#{code}"                  # Start tablecell
          if colspan && c == row.length             # If we're on the last cell, and need a colspan
            output << " colspan=\"#{colspan}\">"    # Add colspan
          else                                      # Otherwise
            output << ">"                           # Just close bracket
          end
          output << sanitize(field)                 # Sanitize text
          output << "</#{code}>\n"                  # Close tablecell
        end
        output << "\t</tr>\n"                       # And close row
        r += 1
      end
      output << "</table>\n"                        # And close table
    end

    # METHOD: form_of_list(text)
    # Formats block of text as a list
    def form_of_list(text)
      output = "<ul>\n"
      listdepth = 1
      # If there are dividers, remove "\n"s
      text.gsub!(/[:]+[ \n\t]*/,": ")
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
      sanitize(output)
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
      # Strip off white space on either side
      output.strip
    end
  end
end