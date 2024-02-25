require 'gosu'  # Import the Gosu library for game development
require 'ruby2d'  # Import the Ruby2D library 

class GameWindow < Gosu::Window  # Define a class GameWindow inheriting from Gosu::Window
  def initialize  # Initialize the game window and set up initial variables
    super(843, 462, false)  # Create a window with dimensions 843x462 and not fullscreen
    self.caption = 'ARAM'  # Set the window title
    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)  # Load a font for text rendering
    @background = Gosu::Image.new('images/bilgewater.png', retro: true)  # Load background image

    @character = Gosu::Image.new(self, 'images/Teemo.gif', retro: true)  # Load character image
    @character_scale = 0.1  # Set character scale for rendering
    # Initialize character position and target position
    @character_x = 80
    @character_y = 270
    @target_x = @character_x
    @target_y = @character_y
    # Set up character variables for the profile
    @health_color = Gosu::Color.new(255, 215, 0)
    @teemo_health = 75
    @teemoDart=Gosu::Sample.new('music_sfx/teemoDart.mp3')  # Load character's attack sound

    @opponent = Gosu::Image.new('images/jhin.gif', retro: true)  # Load opponent image
    @opponent_scale = 0.5  # Set opponent scale for rendering
    # Initialize opponent position and health
    @opponent_x = 760
    @opponent_y = 230
    @opponent_health=75

    # Set up game physics variables
    @speed = 1.0
    @threshold = 5.0
    @damping = 0.9

    # Initialize variables for displaying text and victory/defeat screens
    @display_text = true
    @text_timer = 0
    @time_passed = 0
    @defeat_popup = Gosu::Image.new('images/defeat_screen.png', retro: true)
    @victory_popup = Gosu::Image.new('images/victory.png', retro: true)
    @closeGametext = Gosu::Font.new(self, Gosu::default_font_name, 30)
    @defeat = false
    @victory = false

    # Record game start time and last damage time
    @game_start_time = Gosu.milliseconds
    @last_damage_time = Gosu.milliseconds
    @last_movement_time = 0

    # Load and play background music and intro sound
    @backgroundMusic = Gosu::Song.new('music_sfx/backMusic.mp3')
    @backgroundMusic.volume=0.4
    @backgroundMusic.play(true)
    @intro_sound = Gosu::Sample.new('music_sfx/intro_speech.mp3')
    @intro_sound.play

    # Initialize flags for danger zone and sound play
    @in_danger_zone = false
    @sound_played = false
  end

  def update  # Update game logic
    move_character  # Move the character
    move_opponent_to_center  # Move the opponent
    update_text_timer  # Update text timer
    apply_damage_constant if @character_x >= 630 - 65 && @character_x <= 630 + 65  # Apply damage to character if character is in range
    apply_damage_constant_opponent if @opponent_x-@character_x<= 30 and @character_x-@opponent_x<=30  # Apply damage to opponent if character is close
  end

  def draw  # Render game elements
    @background.draw(0, 0, 0)  # Draw background
    @character.draw(@character_x - @character_width / 2.6, @character_y - @character_height / 1.5, 1, @character_scale, @character_scale)  # Draw character
    @opponent.draw(@opponent_x - @opponent_width / 2, @opponent_y - @opponent_height / 2, 1, @opponent_scale, @opponent_scale)  # Draw opponent
    draw_rect(@character_x - 30, @character_y - 65, 75, 7, Gosu::Color::WHITE)  # Draw character health bar background
    draw_rect(@character_x - 30, @character_y - 65, [@teemo_health, 0].max, 7, @health_color)  # Draw character health bar
    draw_rect(@opponent_x - 40, @opponent_y - 55, 75, 7, Gosu::Color::WHITE)  # Draw opponent health bar background
    draw_rect(@opponent_x - 40, @opponent_y - 55,@opponent_health, 7, Gosu::Color::RED)  # Draw opponent health bar
    # Draw danger zone circle
    color = Gosu::Color.rgba(255, 0, 0, 70)  # Set color for danger zone circle
    @enemy_turret1_dangerZone = draw_circle(630, 290, 65, color)  # Draw danger zone circle
    super  # Call parent draw method
    # Draw victory/defeat screens if conditions met
    if @teemo_health <= 0 or @time_passed >= 600
      @defeat_popup.draw(110, -80, 1)
      @closeGametext.draw("Close game", 337, 260, 3)
      draw_rect(330, 260, 160, 30, Gosu::Color::RED, 1)
      @defeat = true
    end
    if @opponent_health <= 0
      @victory_popup.draw(110, -10, 1)
      @closeGametext.draw("Close game", 337, 260, 3)
      draw_rect(330, 260, 160, 30, Gosu::Color::RED, 1)
      @victory = true
    end
    # Draw danger zone circle if character is in range
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
    @font.draw(format_time(@time_passed), 790, 5, 1, 1.0, 1.0, Gosu::Color::WHITE)  # Draw game time
    @font.draw("Welcome to the Howling Abyss!", 180, 100, 1, 2.0, 2.0, Gosu::Color::YELLOW) if @display_text  # Draw welcome message while @display_text is true
  end

  def format_time(time)  # Format time as "MM:SS"
    minutes = time / 60
    seconds = time % 60
    sprintf("%02d:%02d", minutes, seconds)
  end

  # Move the character towards the target position
  def move_character
    direction_x, direction_y = normalize(@target_x - @character_x, @target_y - @character_y)
    distance = Math.sqrt((@target_x - @character_x)**2 + (@target_y - @character_y)**2)
    if distance > @threshold
      @character_x += direction_x * @speed  # Move character horizontally
      @character_y += direction_y * @speed  # Move character vertically
    else
      @character_x += (direction_x * @speed * @damping) # Slow down character horizontally
      @character_y += (direction_y * @speed * @damping) # Slow down character vertically
    end
  end

  # Update text timer
  def update_text_timer
    @text_timer += 1 # Increment text timer
    @display_text = false if @text_timer >= 450 # Disable text display if timer exceeds certain value
  end

  # Apply constant damage to the character
  def apply_damage_constant
    current_time = Gosu.milliseconds
    time_since_last_damage = current_time - @last_damage_time
    if time_since_last_damage >= 1000 # Check if time since last damage is greater than or equal to 1000 milliseconds
      @teemo_health -= 10 #decrement 10 health points
      @teemo_health = [@teemo_health, 0].max #ensure that health does not go below 0
      @last_damage_time = current_time # Update last damage time
    end
  end

  # Apply constant damage to the opponent
  def apply_damage_constant_opponent
    current_time = Gosu.milliseconds
    time_since_last_damage = current_time - @last_damage_time
    if time_since_last_damage >= 1000 # Check if time since last damage is greater than or equal to 1000 milliseconds
      @opponent_health -= 10 #decrement 10 health points
      @teemoDart.play unless @victory or @defeat # Play Teemo's dart sound unless victory or defeat has occurred
      @opponent_health = [@opponent_health, 0].max #ensure that health does not go below 0
      @last_damage_time = current_time # Update last damage time
    end
  end

  # Render a circle
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

  # Normalize a vector
  def normalize(x, y)
    magnitude = Math.sqrt(x**2 + y**2)
    return [0, 0] if magnitude.zero?
    [x / magnitude, y / magnitude]
  end

  # Move the opponent towards the center of the map
  def move_opponent_to_center
    if @opponent_x > 422
      direction_x, direction_y = normalize(422 - @opponent_x, 230 - @opponent_y)
      @opponent_x += direction_x * @speed
      @opponent_y += direction_y * @speed
    end
  end

  # Include a cursor on the display
  def needs_cursor?
    true
  end

  # Handle leftmousebutton click events
  def button_down(id)
    if @defeat or @victory
      case id
      when Gosu::MsLeft
        if mouse_x >= 330 && mouse_x <= 330 + 160 && mouse_y >= 260 && mouse_y <= 260 + 30
          close # Close the game window if clicked on close button
        end
      end
    else
      case id
      when Gosu::MsLeft
        if mouse_y > 210 && mouse_y < 360 # Check if mouse Y position is within character movement range
          @target_x = mouse_x # Set target X position to mouse X position
          @target_y = mouse_y # Set target Y position to mouse Y position
        end
      end
    end
  end
end

window = GameWindow.new  # Create an instance of GameWindow
window.show  # Start the game loop
