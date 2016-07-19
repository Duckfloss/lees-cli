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

    def chop
      puts "Chopping up #{@total} images."

      @images.each do |image|
        if @eci
          $log.info "Outputting images to ECI"
        end

        chopup(image)

        # Log what's left
        @total -= 1
        $log.info "#{@total} images left to parse"
      end
    end

    private

    # METHOD: Chop up image into selected formats
    def chopup(image)
      # Begin reporting
      $log.info "Parsing #{image}"

      outputs = []

      # Parse filename
      filebase = image.slice(/^[A-Z]{16}/)
      fileattr = image.slice(/(?<=\_)([A-Za-z0-9\_]+)(?=\.)/)

      # Check if parsing to ECI
      if @eci
        # If we haven't already done it, output to ECI
        if !@parsed.include?(filebase)
          outputs << { size: 350, dest: ECI_PATH, name: "#{filebase}.jpg" }
          outputs << { size: 100, dest: ECI_PATH, name: "#{filebase}t.jpg" }
        end
      end

      # Collect other formats
      @formats.each do |format|
        outputs << { size: SIZE[format], dest: @dest, name: "#{File.basename(image,".*")}_#{TAG[format]}.jpg" }
      end

      # Sort the $outputs array by size
      outputs.sort! { |x,y| x[:size] <=> y[:size] }
      outputs.reverse!

      # Create new image object and set defaults
      imageout = ImageList.new("#{@source}/#{image}") do
        self.background_color = "#ffffff"
        self.gravity = CenterGravity
      end

      preformat_image!(imageout)

      # Chop up image
      outputs.each do |output|
        # Resize image
        imageout.resize!(output[:size],output[:size])

        # Save resized image
        write_file(imageout, "#{output[:dest]}/#{output[:name]}")

        # If we need it, save a bare large image
        if output[:size] == 1050 && !@parsed.include?(filebase)
          write_file(imageout, "#{output[:dest]}/#{filebase}.jpg")
        end

        if output[:dest] == "R:/RETAIL/RPRO/Images/Inven"
          $log.info "Saved to ECI: #{output[:name]}"
        else
          $log.info "Saved to dest: #{output[:name]}"
        end
        
      end

      # We only need to parse to ECI and large bare files once
      # So add name to parsed file list
      if !@parsed.include?(filebase)
        @parsed << filebase
      end

      # Kill this whole endealment and clean out garbage
      imageout.destroy!
      GC.start
    end

    # METHOD: Preformats image in advance of chopping it up
    def preformat_image!(image)
      @image = image
      # If the image is CMYK, change it to RGB
      if @image.colorspace == Magick::CMYKColorspace
        @image = @image.add_profile(COLOR_PROFILE)
      end

      # If the image has alpha channel transparency, fill it with background color
      if @image.alpha?
        @image.alpha(BackgroundAlphaChannel)
      end

      # If the image size isn't a square, make it a square
      img_w = @image.columns
      img_h = @image.rows
      ratio = img_w.to_f/img_h.to_f
      if ratio < 1
        x = img_h/2-img_w/2
        @image = @image.extent(img_h,img_h,x=-x,y=0)
      elsif ratio > 1
        y = img_w/2-img_h/2
        @image = @image.extent(img_w,img_w,x=0,y=-y)
      end

      return self
    end

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

    # METHOD: Writes new files to destination
    def write_file(image,dest)
      image.write(dest) do
        self.quality = 80
        self.density = "72x72"
      end
    end

  end
end