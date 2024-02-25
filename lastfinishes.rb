require 'gosu'
require 'ruby2d'

class GameWindow < Gosu::Window
  def initialize
    super(843, 462, false)
    self.caption = 'ARAM'
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @background = Gosu::Image.new('images/bilgewater.png', retro: true)

    @character = Gosu::Image.new(self, 'images/Teemo.gif', retro: true)
    @character_scale = 0.1
    @character_width = @character.width * @character_scale
    @character_height = @character.height * @character_scale
    @character_x = 80
    @character_y = 270
    @target_x = @character_x
    @target_y = @character_y
    @health_color = Gosu::Color.new(255, 215, 0)
    @teemo_health = 75
    @teemoDart=Gosu::Sample.new('music_sfx/teemoDart.mp3')

    @opponent = Gosu::Image.new('images/jhin.gif', retro: true)
    @opponent_scale = 0.5
    @opponent_width = @opponent.width * @opponent_scale
    @opponent_height = @opponent.height * @opponent_scale
    @opponent_x = 760
    @opponent_y = 230
    @opponent_health=75

    @speed = 1.0
    @threshold = 5.0
    @damping = 0.9

    @display_text = true
    @text_timer = 0
    @time_passed = 0
    @defeat_popup = Gosu::Image.new('images/defeat_screen.png', retro: true)
    @victory_popup =Gosu::Image.new('images/victory.png', retro:true)
    @closeGametext= Gosu::Font.new(self, Gosu::default_font_name,30)
    @defeat=false
    @victory=false

    @game_start_time = Gosu.milliseconds  # Record the start time of the game
    @last_damage_time = Gosu.milliseconds  # Initialize the time of last damage taken
    @last_movement_time = 0  # Initialize the time of last opponent movement

    @backgroundMusic = Gosu::Song.new('music_sfx/backMusic.mp3')
    @backgroundMusic.volume=0.4
    @backgroundMusic.play(true)
    @intro_sound = Gosu::Sample.new('music_sfx/intro_speech.mp3')
    @intro_sound.play # true argument makes the song loop
    @turret_targeted = Gosu::Sample.new('music_sfx/lol_turret_targeting.mp3')

    @in_danger_zone = false  # Flag to track whether the character is in the danger zone
    @sound_played = false  # Flag to track whether the targeting sound has been played

  end


  def update
    move_character
    move_opponent_to_center
    update_text_timer
    apply_damage_constant if @character_x >= 630 - 65 && @character_x <= 630 + 65

    if @defeat == false or @victory==false
      @time_passed = (Gosu.milliseconds - @game_start_time) / 1000
    end

    if @opponent_x-@character_x<= 30 and @character_x-@opponent_x<=30
       apply_damage_constant_opponent      
    end
      
  end

  def draw
    @background.draw(0, 0, 0)
    @character.draw(@character_x - @character_width / 2.6, @character_y - @character_height / 1.5, 1, @character_scale, @character_scale)
    @opponent.draw(@opponent_x - @opponent_width / 2, @opponent_y - @opponent_height / 2, 1, @opponent_scale, @opponent_scale)
    draw_rect(@character_x - 30, @character_y - 65, 75, 7, Gosu::Color::WHITE) # healthbar_background
    draw_rect(@character_x - 30, @character_y - 65, [@teemo_health, 0].max, 7, @health_color) # Ensure teemo_health doesn't go below 0
    draw_rect(@opponent_x - 40, @opponent_y - 55, 75, 7, Gosu::Color::WHITE) # opp_healt_background
    draw_rect(@opponent_x - 40, @opponent_y - 55,@opponent_health, 7, Gosu::Color::RED)
    color = Gosu::Color.rgba(255, 0, 0, 70) # when not in turret radius 50% opacity circle(70 out of 255)
    @enemy_turret1_dangerZone = draw_circle(630, 290, 65, color)
    super

    if @teemo_health <= 0 or @time_passed >= 600 # 10 minutes
      @defeat_popup.draw(110, -80, 1)
      @closeGametext.draw("Close game", 337, 260, 3)
      draw_rect(330, 260, 160, 30, Gosu::Color::RED,1)
      @defeat=true
    end
    if @opponent_health<=0 
      @victory_popup.draw(110, -10, 1)
      @closeGametext.draw("Close game", 337, 260, 3)
      draw_rect(330, 260, 160, 30, Gosu::Color::RED,1)
      @victory=true
    end

    if @character_x >= 630 - 65 && @character_x <= 630 + 65
      draw_circle(630, 290, 65, Gosu::Color.rgba(255, 0, 0, 255))
      if !@in_danger_zone && !@sound_played
        @turret_targeted.play
        @sound_played = true
      end
      @in_danger_zone = true
    else
      @in_danger_zone = false
      @sound_played = false
    end
    
    @font.draw(format_time(@time_passed), 790, 5, 1, 1.0, 1.0, Gosu::Color::WHITE)

    if @display_text
      @font.draw("Welcome to the Howling Abyss!", 180, 100, 1, 2.0, 2.0, Gosu::Color::YELLOW)
    end
  end

  def format_time(time)
    minutes = time / 60
    seconds = time % 60
    sprintf("%02d:%02d", minutes, seconds)  # Format time as "MM:SS"
  end

  def move_character
    direction_x, direction_y = normalize(@target_x - @character_x, @target_y - @character_y)

    distance = Math.sqrt((@target_x - @character_x)**2 + (@target_y - @character_y)**2)

    if distance > @threshold
      @character_x += direction_x * @speed
      @character_y += direction_y * @speed
    else
      @character_x += (direction_x * @speed * @damping)
      @character_y += (direction_y * @speed * @damping)
    end
  end

  def update_text_timer
    @text_timer += 1

    if @text_timer >= 450 # Adjust the time (in frames) for how long you want the text to be displayed
      @display_text = false
    end
  end

  def apply_damage_constant
    current_time = Gosu.milliseconds
    time_since_last_damage = current_time - @last_damage_time

    if time_since_last_damage >= 1000  # Five seconds
      @teemo_health -= 10
      @teemo_health = [@teemo_health, 0].max  # Ensure teemo_health doesn't go below 0
      @last_damage_time = current_time
    end
  end
  def apply_damage_constant_opponent
    current_time = Gosu.milliseconds
    time_since_last_damage = current_time - @last_damage_time

    if time_since_last_damage >= 1000  # Five seconds
      @opponent_health -= 10
      if @victory==false and @defeat==false
      @teemoDart.play
      end
      @opponent_health = [@opponent_health, 0].max  # Ensure teemo_health doesn't go below 0
      @last_damage_time = current_time
    end
  end

  def draw_circle(x, y, radius, color)
    num_segments = 30
    step = (Math::PI * 2) / num_segments

    num_segments.times do |i|
      x1 = x + radius * Math.cos(i * step)
      y1 = y + radius * Math.sin(i * step)

      x2 = x + radius * Math.cos((i + 1) * step)
      y2 = y + radius * Math.sin((i + 1) * step)

      draw_line(x1, y1, color, x2, y2, color, z = 0)
    end
  end

  def normalize(x, y)
    magnitude = Math.sqrt(x**2 + y**2)
    return [0, 0] if magnitude.zero?

    [x / magnitude, y / magnitude]
  end

  def move_opponent_to_center
    if @opponent_x > 422
      direction_x, direction_y = normalize(422 - @opponent_x, 230 - @opponent_y)
      @opponent_x += direction_x * @speed
      @opponent_y += direction_y * @speed
    
    end
  end

  def needs_cursor? #include a cursor on the display
    true
  end

  def button_down(id)
    if @defeat or @victory
      case id
      when Gosu::MsLeft
        if mouse_x >= 330 && mouse_x <= 330 + 160 && mouse_y >= 260 && mouse_y <= 260 + 30 #you can only left click the close button
          close
        end
      end
    else
      case id
      when Gosu::MsLeft
        if mouse_y > 210 && mouse_y < 360 #the clickable y coordinates
          @target_x = mouse_x
          @target_y = mouse_y
        end
      end
    end
  end
end

window = GameWindow.new
window.show

