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

    def update()
        return if (!@db)

        @model.clear

        @db.images.each{|im|
            next if (!im.display)
            iter = @model.append
            @model.set_value(iter, 0, im)
            @model.set_value(iter, 1, im.thumbnail)
            name = im.filename
            name += " (#{im.rank})" if (im.rank > 0)
            @model.set_value(iter, 2, name)
        }

        @bgthread.kill if (@bgthread)

        @bgthread = Thread.new {
            list = []
            
            @model.each{|model, path, iter|
                im = @model.get_value(iter, 0)
                im.genthumbnail
                @model.set_value(iter, 1, im.thumbnail)
            }
        }
    end

    def set_database(db)
        @db = db

        update()
    end
end

