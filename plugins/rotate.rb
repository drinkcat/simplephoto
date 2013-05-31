
class Rotate
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "r" ]
        @image = nil
        @callback = callback
    end

    def getwidget()
        box = Gtk::VBox.new(false, 0)
        @rotatelabel = Gtk::Label.new("Rotate: " + 0.to_s)
        box.pack_start(@rotatelabel, false, false, 0)
        return box
    end

    def activate(key)
        alt = @image.getcurrentalt(true)
        if (!@levelmod) then
            @levelmod = RotateModifier.new(90)
            alt.modifiers << @levelmod
        else
            @levelmod.degree = (@levelmod.degree + 90) % 360
        end
        @rotatelabel.text = "Rotate: " + @levelmod.degree.to_s
        @callback.updateimage()
    end

    def imagechanged(image)
        @image = nil
        alt = image.getcurrentalt(false)
        @levelmod = alt ? alt.modifiers.find{|x| x.class == RotateModifier} : nil
        if (@levelmod) then
            @rotatelabel.text = "Rotate: " + @levelmod.degree.to_s
        else
            @rotatelabel.text = "Rotate: " + 0.to_s
        end
        @image = image
    end
end

class RotateModifier
    attr_accessor :degree
    
    def initialize(degree)
        @degree = degree
    end

    def apply(image)
        image.rotate(degree)
    end
end

