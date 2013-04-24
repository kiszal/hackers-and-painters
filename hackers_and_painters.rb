require 'net/http'
require 'chunky_png'
require "base64"
require "json"

TOKEN = "unleash sticky models"
PIC_NAME = 'rainbow.png'
COLORS = {:r => 0, :g => 1, :b => 2}

class Image
  attr_accessor :color
  attr_accessor :image_id, :dimension, :picture, :png, :desired_red, :desired_green, :desired_blue

  def initialize
    get_data
    self.dimension = 64
    create_picture
    send_solution
  end

  def get_data
    uri = URI('http://canvas.hackkrk.com/api/new_challenge')
    res = Net::HTTP.post_form(uri, 'api_token' => TOKEN)
    json = JSON.parse(res.body)
    self.image_id = json["id"]
    self.color = json["color"]
    self.desired_red = json["color"][0]
    self.desired_green = json["color"][1]
    self.desired_blue = json["color"][2]
  end

  def create_picture
    self.png = ChunkyPNG::Image.from_file(PIC_NAME)
    normalize_colors
    self.png.save(PIC_NAME)
  end

  def decrease_color(method_color)
    64.times do |i|
      64.times do |j|
        current_color = ChunkyPNG::Color.to_truecolor_alpha_bytes(png[i,j])
        current_color[COLORS[method_color]] > 0 ? current_color[COLORS[method_color]] -= 1 : false
        png[i, j] = ChunkyPNG::Color.rgba(*current_color) 
      end
    end    
  end

  def increase_color(method_color)
    64.times do |i|
      64.times do |j|
        current_color = ChunkyPNG::Color.to_truecolor_alpha_bytes(png[i,j])
        current_color[COLORS[method_color]] < 255 ? current_color[COLORS[method_color]] += 1 : false
        png[i, j] = ChunkyPNG::Color.rgba(*current_color) 
      end
    end    
  end

  def normalize_colors
    while (current_red = average_color(:r)) != desired_red
      current_red > desired_red ? decrease_color(:r) : increase_color(:r)
    end
    while (current_blue = average_color(:b)) != desired_blue
      current_blue > desired_blue ? decrease_color(:b) : increase_color(:b)
    end
    while (current_green = average_color(:g)) != desired_green
      current_green > desired_green ? decrease_color(:g) : increase_color(:g)
    end
  end

  def average_color(method_color)
    red_total = 0
    64.times do |i|
      64.times do |j|
        red_total += ChunkyPNG::Color.send(method_color, png[i, j]) 
      end
    end    
    red_total/(64*64)
  end

  def send_solution
    uri = URI("http://canvas.hackkrk.com/api/challenge/#{self.image_id}")
    base64_image =  Base64.encode64(File.read(PIC_NAME))
    res = Net::HTTP.post_form(uri, 'api_token' => TOKEN, 'image' => base64_image)
    puts res.body
  end

end

Image.new
