
class Rank
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "0", "1", "2", "3", "4", "5" ]
        @image = nil
        @callback = callback
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        @ranktext = Gtk::Label.new("Rank: N/A")
        box.pack_start(@ranktext, false, false, 0)
        return box
    end

    def activate(key)
        i = key.to_i
        @image.rank = i if (@image && i >= 0 && i <= 5)
        imagechanged(@image)
    end

    def imagechanged(image)
        @image = image
        t = "N/A"
        if (@image) then
            t = @image.rank.to_s
        end

        @ranktext.text = "Rank: #{t}"
    end
end


class RankMulti
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "0", "1", "2", "3", "4", "5" ]
        @mingood = 0
        @db = nil
        @callback = callback
    end

    def getwidget()
        return nil
    end

    def activate(key)
        return if (!@db)
        i = key.to_i
        @mingood = i if (i >= 0 && i <= 5)
        @db.images.each{|im|
            im.display = im.rank >= @mingood
        }
        @callback.updateimagelist()
    end

    def dbchanged(db)
        @db = db
    end
end


