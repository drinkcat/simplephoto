

class DirTree < Gtk::TreeView
    def initialize(base)
        super()
        @base = base
    end
end
