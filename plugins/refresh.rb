
require 'fileutils'

class Refresh
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
        @callback.updateimagelist()
    end

    def dbchanged(db)
        @db = db
    end
end

