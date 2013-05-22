require 'parallel'

class PhotoList < Gtk::IconView
    attr_reader :bgthread

    def initialize()
        super()
        @bgthread = nil
        @dir = nil

        set_pixbuf_column(1)
        set_text_column(2)
        set_selection_mode(Gtk::SELECTION_MULTIPLE)
        set_columns(0)
        set_item_width(DEFAULT_IMAGE_WIDTH+50)

        # Setup ListStore:
        # Full Path; Thumbnail; Filename
        @model = Gtk::ListStore.new(String, Gdk::Pixbuf, String)

        set_model(@model)
    end

    def set_directory(dir)
        @dir = dir

        images = Dir.new(dir).to_a.sort!

        $blank = Gdk::Pixbuf.new(Gdk::Pixbuf::COLORSPACE_RGB, false, 8, DEFAULT_IMAGE_WIDTH, DEFAULT_IMAGE_WIDTH*3/4)

        images.each{|im|
            next if (im.upcase !~ /.*JPG/)
            iter = @model.append
            @model.set_value(iter, 0, dir + "/" + im)
            @model.set_value(iter, 1, $blank)
            @model.set_value(iter, 2, im)
        }

        @bgthread = Thread.new {
            list = []
            
            @model.each{|model, path, iter|
                list << @model.get_value(iter, 0)
            }

            GC.start
            results = Parallel.map(list) do |filepath|
                puts "#{path}"
                pixbuf = Magick::Image::read(filepath).first
                
                pix_w = pixbuf.columns
                pix_h = pixbuf.rows
                new_h = (pix_h * DEFAULT_IMAGE_WIDTH) / pix_w   # Calculate the scaled height before resizing image
                out = [filepath, pixbuf.resize(DEFAULT_IMAGE_WIDTH, new_h)]
                pixbuf.destroy!
                out
            end

            @model.each{|model, path, iter|
                filepath = @model.get_value(iter, 0)
                scaled_pix = results.find{|x| x[0] == filepath}[1]
                pixbuf = Gdk::Pixbuf.new(scaled_pix.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                            false, 8, scaled_pix.columns, scaled_pix.rows, scaled_pix.columns*3)
                @model.set_value(iter, 1, pixbuf)
                scaled_pix.destroy!
            }
        }
    end
end
