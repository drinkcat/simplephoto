DEFAULT_IMAGE_WIDTH = 200
DEFAULT_IMAGE_HEIGHT = DEFAULT_IMAGE_WIDTH*3/4
FIRST_EXIF = [ "FocalLength", "ExposureTime", "FNumber", "ISO", "WhiteBalance", "Flash" ]
ORIGSDIR = "/home/nicolas/photos/origs"
SELECTDIR = "/home/nicolas/photos/select"

# Plugins for single photo editing
PLUGINS = {
    "description.rb" => "Description",
    "rank.rb" => "Rank",
    "levels.rb" => "Levels",
    "rotate.rb" => "Rotate"
}

# Plugins for multiple photo editing
PLUGINS_MULTI = {
    "rank.rb" => "RankMulti",
    "export.rb" => "Export"    
}


