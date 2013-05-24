
require 'fileutils'

class Export
    attr_reader :accel
    
    def initialize(callback)
        @accel = [ "e" ]
        @db = nil
        @callback = callback
    end

    def getwidget()
        return nil
    end

    def activate(key)
        return if (!@db)
        origsdir = @db.directory
        puts "Origs directory: " + origsdir
        if (!match = origsdir.match(/^#{ORIGSDIR}(.*)$/)) then
            puts "ERROR: #{origsdir} does not start with #{ORIGSDIR}"
            return
        end
        selectdir = "#{SELECTDIR}#{match[1]}"
        puts "Select directory: " + selectdir
        FileUtils.mkdir_p(selectdir) if (!File.exist?(selectdir))

        comments = File.open("#{selectdir}/comments", "w")
        commentsall = File.open("#{selectdir}/comments.all", "w")

        @db.images.each{|im|
            next if (im.rank == 0)
            outfile = "#{selectdir}/#{im.filename}"
            puts im.filename

            commentsall.puts "#{im.filename}|#{im.description}"

            if (File.exist?(outfile)) then
                puts "Already exists..."
            else
                im.export(outfile)
                comments.puts "#{im.filename}|#{im.description}"
            end
        }

        comments.close
        commentsall.close

        puts "Done"
    end

    def dbchanged(db)
        @db = db
    end
end

