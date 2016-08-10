require 'RMagick'

module LeesToolbox

  def self.run(params)
    imagelist = Image_Chopper.new(params)
    imagelist.chop
  end

  class Image_Chopper

    include Magick

    SIZE = {  "large"=>1050,
              "medium"=>350,
              "swatch"=>350, # this is temporary til I figure out how to automate it
              "thumb"=>100 }

    TAG = { "large"=>"lg", "medium"=>"med", "swatch"=>"sw", "thumb"=>"t" }

    ECI_PATH = "R:/RETAIL/RPRO/Images/Inven"

    COLOR_PROFILE = "C:/WINDOWS/system32/spool/drivers/color/sRGB Color Space Profile.icm"

    def initialize(params)
      @source = params[:source]
      @images = piclist(params[:source])
      @dest = params[:dest]
      @formats = params[:format]
      @eci = params[:eci]
      @total = @images.length
      @parsed = []
    end

    ##
    # METHOD: chop
    def chop
      puts "Chopping up #{@total} images."                    # Message STDOUT
      if @eci then $log.info "Outputting images to ECI" end   # Log if we're doing ECI
      @images.each do |image|                                 # For each image
        chopup(image)                                         # Chopitup
        @total -= 1                                           # Decrement total
        $log.info "#{@total} images left to parse"            # Log what's left
      end
    end

    private

    ##
    # METHOD: chopup(image)
    # Chop up image into selected formats
    def chopup(image)
      $log.info "Parsing #{image}"                  # Begin reporting
      outputs = []                                  # For listing each format
      filebase = image.slice(/^[A-Z]{16}/)          # Get product SID
      fileattr = image.slice(/(?<=\_)([A-Za-z0-9\_]+)(?=\.)/)     # Get product attribute
      if @eci                                       # Check if we're parsing to ECI
        if !@parsed.include?(filebase)              # Check if we've already done this image
          outputs << { size: 350, dest: ECI_PATH, name: "#{filebase}.jpg" }
          outputs << { size: 100, dest: ECI_PATH, name: "#{filebase}t.jpg" }
        end
      end
      @formats.each do |format|                     # Collect other formats into output array
        outputs << { size: SIZE[format], dest: @dest, name: "#{File.basename(image,".*")}_#{TAG[format]}.jpg" }
      end
      outputs.sort! { |x,y| x[:size] <=> y[:size] } # Sort outputs by size
      outputs.reverse!                              # And reverse (from large to small)
      # Create new image object and set defaults
      imageout = ImageList.new("#{@source}/#{image}") do
        self.background_color = "#ffffff"           # Default: White background
        self.gravity = CenterGravity                # Default: Center image
      end
      imageout = preformat_image(imageout)          # Do preformatting on image
      outputs.each do |output|                      # For each format
        imageout.resize!(output[:size],output[:size])               # Size it
        write_file(imageout, "#{output[:dest]}/#{output[:name]}")   # And save it
        if output[:size] == 1050 && !@parsed.include?(filebase)     # Save default large copy
         write_file(imageout, "#{output[:dest]}/#{filebase}_lg.jpg")
        end
        # And log it
        if output[:dest] == "R:/RETAIL/RPRO/Images/Inven"
          $log.info "Saved to ECI: #{output[:name]}"
        else
          $log.info "Saved to dest: #{output[:name]}"
        end
      end
      # We only need to parse to ECI and default large files once
      # So add name to parsed file list
      if !@parsed.include?(filebase)
        @parsed << filebase
      end
      imageout.destroy!      # To clear memory, ditch this file
      GC.start               # And take out the trash
    end

    ##
    # METHOD: preformat_image(image)
    # Makes it square, clears out alpha channel, etc.
    def preformat_image(image)
      image.density = "72x72"             # Make 72x72
      # Convert to our default color profile (RGB, ftw!)
      if image.colorspace == Magick::CMYKColorspace
        image = image.add_profile(COLOR_PROFILE)
      end
      # If the image has alpha channel transparency, fill it with background color
      if image.alpha?
        image.alpha(BackgroundAlphaChannel)
      end
      # If the image size isn't a square, make it a square
      img_w = image.columns
      img_h = image.rows
      ratio = img_w.to_f/img_h.to_f
      if ratio < 1
        x = img_h/2-img_w/2
        image = image.extent(img_h,img_h,x=-x,y=0)
      elsif ratio > 1
        y = img_w/2-img_h/2
        image = image.extent(img_w,img_w,x=0,y=-y)
      end
      return image
    end

    ##
    # METHOD: Returns list of valid image files
    def piclist(source)
      if File.directory?(source)
        images = Dir.entries(source)
        images.keep_if { |file| file =~ /\.jpg$|\.png$|\.jpeg$|\.gif$/ }
      elsif File.file?(source)
        if [".jpg", ".png", ".jpeg", ".gif"].include?(File.extname(source))
          images = [ source ]
        else
          raise "#{source} is not a valid image file." #error
        end
      else
        raise "Can't find image or directory #{source}" #error
      end
      images
    end

    ##
    # METHOD: Writes new files to destination
    def write_file(image,dest)
      image.write(dest) do
        self.quality = 80                  # Make medium quality
      end
    end
  end
end