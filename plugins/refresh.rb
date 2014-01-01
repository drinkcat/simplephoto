
require 'fileutils'

class Export
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "r" ]
        @db = nil
        @callback = callback
    end

    def getwidget()
        return nil
    end

    def activate(key)
        return if (!@db)
        @db.addimages()

    end

    def dbchanged(db)
        @db = db
    end
end

