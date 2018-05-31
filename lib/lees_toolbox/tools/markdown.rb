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
      @target = "#{path}/#{filename}-FORMATTED#{@type}"
    end

    def translate
     # Detect file encoding
      if CharDet.detect(File.read(@file))["encoding"].upcase != "UTF-8"
        encoding = "Windows-1252:UTF-8"
      else
        encoding = "UTF-8:UTF-8"
      end
      # Open file
      if @type == ".csv"
        nospaces = Proc.new{ |head| head.gsub(" ","_") }    # Special header filter
        data = CSV.open(@file, :headers => true, :header_converters => [:downcase, nospaces], :skip_blanks => true, :encoding => encoding)        # Open CSV
      elsif @type == ".txt"
        data = File.open(@file, "r", :encoding => encoding) # Open File
      end
      write_to_file(parse(data))                            # Parse data and write it to file
    end

    private

    ##
    # METHOD: parse(data)
    # 
    def parse(data)
      if @type == ".csv"                      # If this is a CSV
        descriptions = get_descriptions(data) # We're gonna split it into rows
        output = ["Desc"]
        descriptions.each do |row|
          if row.nil?
            output << ""                      # Don't do blanks
          else
            output << format(row)             # Format each line
          end
        end
      elsif @type == ".txt"                   # If this is just TXT
        output = format(data.read)            # Just format it
      end
      output                                  # And don't forget to return it
    end

    ##
    # METHOD: write_to_file(text)
    # Write text to file
    def write_to_file(data)
      if @type == ".csv"
        CSV.open(@target, "w", :encoding => "UTF-8", :headers => true) do |csv|
          data.each do |row|
            csv << [row]
          end
        end
      elsif @type == ".txt"
        File.open(@target, "w", :encoding => "UTF-8") do |file|
          file << data
        end
      end
    end

    ##
    # METHOD: format
    # Divide text into sections and then filter
    def format(text)
      output = "<ECI>\n<div><font face='verdana'>\n"
      # Divide into hash of sections and format each section
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

    ##
    # METHOD: filter(section)
    # Format section into HTML
    def filter(section)
      # Find if there's a formatting rule for section
      section[0] = section[0].split("#")
      head = section[0][0]
      rule = section[0][1]
      if head == "product_name"
        body = form_of_title(section[1])        # product_name has but one format
      elsif head == "description"
        body = form_of_graf(section[1])         # And description is always a graf
      else                                      # everything else is a list unless otherwise stated
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
      [ head, body ]                            # Return a binary array
    end
    
    ##
    # METHOD: form_of_graf(text)
    # Format text as a paragraph
    def form_of_graf(text)
      text = sanitize(text)                     # Clean up the text
      # If it's more than one graf, put it together with <p>s
      output = text.split("\n")
      output.map! do |line|
        line.strip!
        line.insert(0,"<p>")
        line.insert(-1,"</p>")
      end
      output.join("\n")
    end

    ##
    # METHOD: form_of_table(text)
    # Format text as a table
    def form_of_table(text)
      text.gsub!(/\r\n/,"\n")                       # Clean up newlines
      # Figure out what the seperator is
      commas = text.scan(",").length                # How many commas?
      tabs = text.scan("\t").length                 # How many tabs?
      commas > tabs ? sep="," : sep="\t"            # Whichever is more is the seperator
      if sep == "\t"
        text.gsub!("\t","|")
        sep = "|"
      end
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

    ##
    # METHOD: form_of_list(text)
    # Formats block of text as a list
    def form_of_list(text)
      output = "<ul>\n"
      listdepth = 1                         # Counter for sublists
      text.gsub!(/[:]+[ \n\t]*/,": ")       # If colons, remove extra spaces and linebreaks
      text = text.split("\n")
      # Wrap each line in <li>s
      text.each do |line|
        if line.length < 2 then next end        # Skip empty line
        line.strip!
        if line[0] == "*"                       # If line starts with *, start sublist
          line = sanitize(line)                 # Clean up the text
          line.sub!("*","\t\t<li style=\"list-style:none\"><strong>")
          output << "#{line}</strong>\n"
          output << "\t\t\t<ul>\n"
          listdepth += 1                        # Bump listdepth
        elsif line[0] == "-"                    # If line starts with -, continue sublist
          line = sanitize(line)                 # Clean up the text
          line.sub!("-","\t\t\t\t<li>")
          output << "#{line}</li>\n"
        else                                    # Otherwise, it's not a sublist
          if listdepth > 1                      # Finish sublist if we need to
            listdepth -= 1                      # Decrement listdepth
            output << "\t\t\t</ul>\n\t\t</li>\n"
          end
          output << "\t\t<li>#{sanitize(line)}</li>\n"
        end
      end
      if listdepth > 1                          # If we get to end and haven't closed sublist, do it
        output << "\t\t\t</ul>\n\t\t</li>\n"
      end
      output << "\t</ul>\n"                     # And wrap the whole thing up
    end

    ##
    # METHOD: form_of_title(text)
    # Format text in title case
    def form_of_title(text)
      no_cap = ["a","an","the","with","and","but","or","on","in","at","to"]  # Words we don't cap
      title = text.split                                  # Take white space off ends
      title.map! do |word|                                # Cycle through words
        if word != title[0]                               # Skip: first word is Vendor name
          if word[0] == "*"                               # Skip: word with asterisk (*)
            thisword = word.sub!("*","")
          elsif word[0] =~ /[\.\d]/                       # Skip: digits
            thisword = word
          elsif word.include?('-') && word.length > 1     # Capitalize both sides of hyphens (-)
            thisword = word.split('-').each{|i| i.capitalize!}.join('-')
          elsif no_cap.include?(word.downcase)            # Lowercase 
            thisword = word.downcase
          else
            thisword = word.downcase.capitalize           # Capitalize everything else
          end
        else
          thisword = word
        end
        sanitize(thisword)                                # Clean up the text
      end
      "<h2> #{title.join(' ')} </h2>"                       # Wrap with <h2>s
    end

    ##
    # METHOD: get_descriptions(data)
    # Returns array of descriptions
    def get_descriptions(data)
      # Get just the descriptions column
      # If :desc is present, that's it
      data = data.read                                    # Read data from CSV
      headers = data.headers                              # Get headers
      if headers.include?("desc")                         # If there's a column called "desc"
        descriptions = data["desc"]                       # That's the data we want
      else                                                # Otherwise ...
        header = ""
        while !headers.include?(header)                   # We need to ask which column to use
          puts "Which column has product descriptions?"
          headers.each { |h| puts "\t#{h}" }              # List column heads
          print "#: "                                     # Make user choose column
          header = STDIN.gets.chomp
          descriptions = data[header]                     # Select that column
        end
      end
      descriptions                                        # Don't forget to return data
    end

    ##
    # METHOD: sectionize(text)
    # Divide MD-formatted text into sections
    # Returns paired array
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

    ##
    # METHOD: sanitize(input)
    # Replaces special characters with HTML
    def sanitize(input)
      encoder = HTMLEntities.new(:html4)
      output = encoder.encode(input, :named)              # Convert special characters to HTML
      SPECIAL_CHARS.each do |k,v|                         # Go through and put some characters back
        output.gsub!(k,v)
      end
      while output.include?("\n\n")                       # Get rid of double returns
        output.gsub!("\n\n","\n")
      end
      while output.include?("  ")                         # get rid of double spaces
        output.gsub!("  "," ")
      end
      output.strip                                        # Strip white space off sides
    end
  end
end