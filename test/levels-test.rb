
require 'gtk2'
require 'RMagick'


image = Magick::Image::read("/home/nicolas/photos/origs/2013/05a_random/P1190430.JPG").first

hist = (0..255).map{0}

image.color_histogram.each{|pixel, count|
    hist[(pixel.intensity*255/Magick::QuantumRange).round.to_i] += count
}

sum = hist.inject(0){|sum, t| sum + t}
@histogram = hist.map{|x| x.to_f/sum}

