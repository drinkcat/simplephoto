require 'parallel'

class PhotoList < Gtk::IconView
    attr_reader :bgthread

    def initialize()
        super()
        @bgthread = nil
        @db = nil

        set_pixbuf_column(1)
        set_text_column(2)
        set_selection_mode(Gtk::SELECTION_MULTIPLE)
        set_columns(0)
        set_item_width(DEFAULT_IMAGE_WIDTH+10)

        # Setup ListStore:
        # Full Path; Thumbnail; Filename
        @model = Gtk::ListStore.new(Image, Gdk::Pixbuf, String)

        set_model(@model)
        @pixbufs = []
    end

    def set_database(db)
        @db = db

        db.images.each{|im|
            iter = @model.append
            @model.set_value(iter, 0, im)
            @model.set_value(iter, 1, im.thumbnail)
            @model.set_value(iter, 2, im.filename)
        }

        @bgthread = Thread.new {
            list = []
            
            @model.each{|model, path, iter|
                list << @model.get_value(iter, 0)
            }

            GC.start
            list.each_slice(2){|list_slice|
                results = Parallel.map(list_slice) do |im|
                    puts im.inspect
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

                @model.each{|model, path, iter|
                    im = @model.get_value(iter, 0)
                    next if (!(result = results.find{|x| x[0] == im.fullname}))
                    scaled_pix = result[1]
                    im.thumbnail = Gdk::Pixbuf.new(scaled_pix.export_pixels_to_str(), Gdk::Pixbuf::COLORSPACE_RGB,
                                false, 8, scaled_pix.columns, scaled_pix.rows, scaled_pix.columns*3)
                    @model.set_value(iter, 1, im.thumbnail)
                    scaled_pix.destroy!
                    # Keep a reference of all the pixbufs (so the memory does not get freed)
                    #@pixbufs << pixbuf
                }
            }
        }
    end
end
