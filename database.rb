# Database of current images

require 'json'

$blank = Gdk::Pixbuf.new(Gdk::Pixbuf::COLORSPACE_RGB, false, 8, DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_WIDTH*3/4)

class Database
    attr_reader :directory
    attr_reader :images

    def initialize(directory)
        @directory = directory
        
        @images = []
        Dir.new(directory).to_a.sort!.each{|filename|
            next if (filename.upcase !~ /.*JPG/)
            @images << Image.new(directory, filename)
        }
    end
end

class Image
    attr_reader :filename
    attr_reader :fullname
    attr_reader :description
    attr_reader :rank

    # FIXME: Infrastructure for alternates

    # Non-persistent
    # GDK pixbuf thumbnail
    attr_accessor :thumbnail
    # Display in filelist?
    attr_accessor :display

    def initialize(directory, filename)
        @fullname = directory + "/" + filename
        @filename = filename

        @thumbnail = $blank
        @exif = nil
        @description = ""
        @rank = 0
        @display = true
    end

    def exif
        return @exif if (@exif)
        
        exiftool = `exiftool -json #{@fullname}`
        @exif = JSON.parse(exiftool)[0]
        
        return @exif
    end

    def genthumbnail(force = false)
        return if (@thumbnail != $blank)

        # Hack to make sure thumbnail is really generated in another thread
        results = Parallel.map([self]) do |im|
            # FIXME: Rotate image if EXIF says so
            image = Magick::Image::read(im.fullname).first
            
            pix_w = image.columns
            pix_h = image.rows
            r1 = DEFAULT_IMAGE_WIDTH/pix_w.to_f
            r2 = DEFAULT_IMAGE_HEIGHT/pix_h.to_f
            out = [im.fullname, image.thumbnail([r1, r2].min)]
            image.destroy!
            out
        end

        scaled_pix = results[0][1]
        @thumbnail = Gdk::Pixbuf.new(scaled_pix.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                        false, 8, scaled_pix.columns, scaled_pix.rows, scaled_pix.columns*3)
        scaled_pix.destroy!

        #FIXME: Make sure thumbnail is updated in the listmodel of photolist.rb
    end

    def description=(desc)
        @description = desc
    end


    def rank=(rank)
        @rank = rank
    end
end


