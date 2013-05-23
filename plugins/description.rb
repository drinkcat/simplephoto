
class Description
    attr_reader :priority
    attr_reader :accel
    
    def initialize()
        @priority = -100
        @accel = "d"
        @image = nil
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        @desctext = Gtk::Entry.new()
        box.pack_start(Gtk::Label.new("Description:"), false, false, 0)
        box.pack_start(@desctext, false, false, 0)
        return box
    end

    def activate()
        #FIXME: Set in focus
    end

    def imagechanged(image)
        @image.description = @desctext.text if (@image)
        @image = image
        @desctext.text = @image.description if (@image)
    end
end


