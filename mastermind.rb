# frozen_string_literal: true

# GlobalMethods
module GlobalMethods
  def count_down(message, custom_interval = 3, unique_char = nil)
    i = custom_interval
    print "#{message} -> "
    until i.zero?
      print unique_char || i
      sleep(1)
      i -= 1
    end
    puts ''
  end

  def error_message(player)
    "Error: #{player} is not a valid player, must choose human or computer (case insensitive): "
  end

  def validate_condition?(player)
    player.eql?('human') || player.eql?('computer')
  end

  def prompt_game_mode(role)
    "\nWhat should initial code #{role} be? Human or Computer (case insensitive): "
  end

  def same_index?(guessed_idx, correct_idx)
    guessed_idx.eql?(correct_idx)
  end

  def prompt_columns
    "\nSelect board board_columns, (must be an integer and be between 4 and 8): "
  end

  def prompt_game_number
    prompt = "\nSelect number of games (must be an integer, "
    prompt += 'a positive number, and an even number): '
    prompt
  end
end

# Mastermind
class Mastermind
  include GlobalMethods
  def initialize
    @set = Set.new
    print_welcome_message
    setup_mastermind
    @set.play_set
  end

  private

  def print_welcome_message_one
    puts 'Welcome to Mastermind, Please read the instructions before continuing'
    puts 'This version is different as it uses numbers instead of colours '
    puts '(due to the nature of the CL) to guess the combination.'
  end

  def print_welcome_message_two
    puts "\nThere are 12 rounds to guess the combination code (each digit ranging from 0-9)"
    puts "that the code breaker has set.\n\nIf the code breaker guesses the code, they recieve one "
    puts 'point. If thecode breaker fails round 12, they lose and code breaker recieves 1 points.'
    puts 'If a human code breaker. In both cases, the roles between code maker and code breaker '
  end

  def print_welcome_message_three
    puts 'switch and the next game can proceede. The board will have two sections. The left side'
    puts 'will be where the previous codes have been inputed and the right side is where the clues are posted. '
    puts "\n\nIn this version, '+' symbols mean guessed code contains correct numbers and correct location,"
  end

  def print_welcome_message_four
    puts "'x' means correct number while wrong location and empty squares mean that "
    puts 'there are no (or no more) correct numbers. All clues are in no particular order.'
    puts "\n\nThis game can be played Human vs Computer (and vice versa), "
    puts "Human vs Human, or Computer vs Computer, in the format of 'code maker vs code breaker'"
    puts "Computer code breakers will use '+' to their advantage by reusing the previously "
    puts 'found correct value and location. The initial code breaker (either human or '
    puts 'computer) will choose how many games (must be an even number as roles switch) and how many '
  end

  def print_welcome_message_five
    puts 'board_columns (between 4 and 8 inclusive).  When all the games have been played, '
    puts 'the player with the most points win. If there are fewer games left than the '
    puts 'difference between the winning and losing players, the set (there is only one set '
    puts 'in this version) will end before all the games have been played and the winning player'
    puts 'wins the set since it would be impossible for the losing player to catch up and tie it. '
    puts 'If the results are tied by the end of the set, an extra sudden death game will be played.'
    puts "Finally, it is possible to exit the current game if a human code breaker types 'exit', "
    puts 'but the opponent will gain 2 points as a penalty for being the code breaker being a coward'
  end

  def print_welcome_message
    print_welcome_message_one
    print_welcome_message_two
    print_welcome_message_three
    print_welcome_message_four
    print_welcome_message_five
  end

  def setup_mastermind
    set_game_mode
    set_number_of_games
    set_board
  end

  def validate_game_mode(role)
    print prompt_game_mode(role)
    player = ''
    until validate_condition?(player)
      player = gets.chomp.downcase
      print error_message(player) unless validate_condition?(player)
    end
    player
  end

  def set_game_mode
    @set.code_maker = game_mode_choice(validate_game_mode('maker'), 'code maker')
    @set.code_breaker = game_mode_choice(validate_game_mode('breaker'), 'code breaker')
  end

  def set_number_of_games
    num_of_games = set_game_preferences(game_number_error_prompt, 'number of games', prompt_game_number)
    @set.number_of_games = num_of_games
  end

  def set_board
    board_columns = set_game_preferences(column_error_prompt, 'board columns', prompt_columns)
    board = Board.new(board_columns, @set.code_breaker.name, @set.code_maker.name)
    @set.board = board
    @set.reset_correct_values
  end

  def column_error_prompt
    'and be between 4 and 8'
  end

  def game_number_error_prompt
    'and number must be positive'
  end

  def set_game_preferences(error_prompt, context, prompt)
    @set.code_breaker.select_integers(error_prompt, context, prompt)
  end

  def game_mode_choice(player_type, role)
    player_type.eql?('human') ? Human.new(player_type, role) : Computer.new(player_type, role)
  end
end

# Set
class Set
  include GlobalMethods

  attr_accessor :code_maker, :code_breaker, :number_of_games, :board, :found_correct_values

  def initialize
    @game_number = 0
  end

  def play_set
    until @game_number.eql?(@number_of_games) || tying_impossible?
      @game_number += 1
      depict_game_winner(play_game)
      set_tied_at_end
      reset_correct_values
    end
    puts "Congrats!!! #{player_status.name}, you earned the most points and won the set, Goodbye"
  end

  def reset_correct_values
    @found_correct_values = Array.new(@board.board_columns)
  end

  def player_status(get_losing_player: false)
    if get_losing_player
      @code_maker.points > @code_breaker.points ? @code_breaker : @code_maker
    else
      @code_maker.points < @code_breaker.points ? @code_breaker : @code_maker
    end
  end

  def set_tied_at_end
    return unless @game_number.eql?(@number_of_games) && game_tied?

    puts 'Points are tied, sudden death will be played '
    @number_of_games += 1
  end

  def depict_game_winner(clues)
    @board.clear_board
    if clues.join.downcase.eql?('exit')
      game_winner('(human) has exited the current game therefore', @code_maker, 2)
    elsif clues.length.eql?(@board.board_columns) && clues.all?('+')
      game_winner('guessed the code correctly', @code_breaker)
    else
      game_winner('could not guess the code within 12 rounds', @code_maker)
    end
  end

  def game_winner(prompt, winning_player, score = 1)
    puts "\nEnd of Game #{@game_number}, #{@number_of_games - @game_number} games left"
    puts "\nCode was #{@code.join('')}"
    puts "\n#{@code_breaker.name} #{prompt}\n"
    winning_player.winner(score)
    @board.update_score(@code_breaker.points, @code_maker.points)
    count_down('Giving time to view results', 5)
    return if @game_number.eql?(@number_of_games) || tying_impossible?

    set_tied_at_end
    switch_roles
  end

  def play_game
    puts "\nThis is game #{@game_number}/#{@number_of_games}"
    @code = @code_maker.code(@board.board_columns)
    clues_arr = []
    12.times do
      guessed_code_arr = @code_breaker.guess_code(@board.board_columns, @found_correct_values)
      clues_arr = play_rounds(guessed_code_arr)
      break if game_ended_early?(clues_arr)
    end
    clues_arr
  end

  def game_ended_early?(clues_arr)
    clues_arr.length.eql?(@board.board_columns) && (clues_arr.all?('+') || clues_arr.join('').eql?('exit'))
  end

  def play_rounds(guessed_code_arr)
    clues_arr = []
    if guessed_code_arr.join.eql?('exit')
      clues_arr = guessed_code_arr
    else
      evaluate_guessed_values(guessed_code_arr, clues_arr)
    end
    clues_arr
  end

  def evaluate_guessed_values(guessed_code_arr, clues_arr)
    confirmed_values_arr = []
    ['+', 'x'].each do |symbol|
      compare_guessed_values(guessed_code_arr, clues_arr, confirmed_values_arr, symbol)
    end
    @board.update_board(guessed_code_arr, clues_arr)
  end

  def compare_guessed_values(guessed_code_arr, clues_arr, confirmed_values_arr, symbol)
    guessed_code_arr.each_with_index do |guessed_number, guessed_idx|
      @code.each_with_index do |correct_number, correct_idx|
        if correct_number.eql?(guessed_number) && confirmed_values_arr.none?(correct_number) &&
           which_symbol?(symbol, guessed_idx, correct_idx, correct_number)
          update_clues(confirmed_values_arr, correct_number, clues_arr, symbol)
        end
      end
    end
  end

  def update_clues(confirmed_values_arr, correct_number, clues_arr, symbol)
    clues_arr.push(symbol)
    confirmed_values_arr.push(correct_number)
  end

  def switch_roles
    puts "\nRoles switched, #{@code_breaker.name.capitalize} is now the code maker"
    puts "while #{@code_maker.name.capitalize} is now the code breaker\n"
    @code_breaker, @code_maker = @code_maker, @code_breaker
    @code_breaker.role, @code_maker.role = @code_maker.role, @code_breaker.role
    @board.switch_players
  end

  def game_tied?
    @code_breaker.points.eql?(@code_maker.points)
  end

  def tying_impossible?
    return false if @game_number.eql?(@number_of_games)

    @number_of_games - @game_number < player_status.points - player_status(get_losing_player: true).points
  end

  def which_symbol?(symbol, guessed_idx, correct_idx, correct_number)
    case symbol
    when '+'
      @found_correct_values[correct_idx] = correct_number if same_index?(guessed_idx, correct_idx)
      same_index?(guessed_idx, correct_idx)
    when 'x' then !same_index?(guessed_idx, correct_idx)
    end
  end
end

# Player
class Player
  include GlobalMethods

  attr_accessor :points, :name, :role, :player_type

  def initialize(player_type, role, name)
    @points = 0
    @name = name
    @role = role
    @player_type = player_type
    puts "#{name.capitalize} will be #{role}\n"
  end

  def select_integers(value, context)
    puts "#{@name.capitalize}, has selected #{value} #{context}"
  end

  def code(board_columns)
    puts "\n#{@name.capitalize} (#{@player_type}, #{@role}), select your secret code.  "
    print "#{prompt_code(board_columns)} and must be unique: "
    count_down('Generating code', board_columns, '*') if @player_type.eql?('computer')
  end

  def guess_code(board_columns, _confirmed_values = [])
    puts "#{@name.capitalize} (#{@player_type}, #{@role}), guess the code. "
    puts "#{prompt_code(board_columns)}. "
    print "Typing 'exit' skips this game and awards the opponent 2 points: "
  end

  def winner(gained_point)
    @points += gained_point
    puts "Congrats #{@name.capitalize} (#{@role}), you won and gained "
    print "#{gained_point} point#{'s' unless gained_point.eql?(1)} "
    puts "#{@name.capitalize} now has #{@points} point#{'s' unless gained_point.eql?(1)} in total"
  end

  private

  def prompt_code(board_columns)
    "Code must contain only #{board_columns} numbers"
  end
end

# Human
class Human < Player
  attr_reader :points, :name

  def initialize(player_type, role)
    puts "\nHuman Was Chosen"
    name = set_name
    super(player_type, role, name)
  end

  def select_integers(error_prompt, input_type, prompt, board_columns = 0)
    value = validate(error_prompt, input_type, board_columns, prompt, must_return_integer: true)
    super(value, input_type)
    value
  end

  def code(board_columns)
    super(board_columns)
    code = validate(prompt_invalid_code(board_columns), 'set', board_columns, '')
    code.split('').map(&:to_i)
  end

  def guess_code(board_columns, _confirmed_values = [])
    super(board_columns)
    code = validate(prompt_invalid_code(board_columns, must_be_unique: true), 'guess', board_columns)
    code.downcase.eql?('exit') ? code.split('') : code.split('').map(&:to_i)
  end

  private

  def validate(error_context, validate_type, board_columns, prompt = '', must_return_integer: false)
    value = nil
    print prompt
    until condition?(value, validate_type, board_columns)
      value = gets.chomp
      error_prompt(error_context) unless condition?(value, validate_type, board_columns)
    end
    must_return_integer ? value.to_i : value.to_s
  end

  def prompt_invalid_code(board_columns, must_be_unique: false)
    prompt = 'code must'
    prompt += ' be unique and' if must_be_unique
    prompt += " only have #{board_columns} characters"
    prompt
  end

  def set_name
    print "\nPlease enter your name: "
    gets.chomp
  end

  def condition?(value, input_type, board_columns)
    return false if value.nil?

    case input_type
    when 'board columns' then correct_number_and_range?(value, 3) && compare_values?(value, 9, find_less_than: true)
    when 'number of games' then correct_number_and_range?(value) && value.to_i.even?
    when 'set' then correct_number_and_length?(value, board_columns, setting_code: true)
    else value.eql?('exit') || correct_number_and_length?(value, board_columns)
    end
  end

  def correct_number_and_range?(value, min_num = 0)
    must_only_have_numbers?(value) && compare_values?(value, min_num)
  end

  def correct_number_and_length?(value, board_columns, setting_code: false)
    must_only_have_numbers?(value) && length_correct?(value, setting_code, board_columns)
  end

  def must_only_have_numbers?(value)
    value.scan(/\D/).empty?
  end

  def compare_values?(val, num, find_less_than: false)
    find_less_than ? val.to_i < num : val.to_i > num
  end

  def length_correct?(value, setting_code, board_columns)
    unique_value = value
    unique_value = unique_value.split('').uniq.join('') if setting_code
    unique_value.length.eql?(board_columns)
  end

  def error_prompt(context)
    print "Invalid entry, value must be an integer, #{context}. Try again: "
  end
end

# Computer
class Computer < Player
  attr_reader :points, :name

  def initialize(player_type, role)
    puts 'Computer was chosen'
    name = "Computer_#{generate_name}"
    super(player_type, role, name)
  end

  def select_integers(_error_prompt, input_type, prompt)
    value = -1
    puts prompt
    count_down("\nComputer selecting #{input_type}")
    input_type.eql?('game number') ? (value = rand(2..22) until value.even?) : value = rand(4..8)
    super(value, input_type)
    value
  end

  def code(board_columns)
    super(board_columns)
    generate_code_arr = []
    generate_correct_code(generate_code_arr, board_columns)
    generate_code_arr
  end

  def guess_code(board_columns, confirmed_values_arr)
    puts ''
    count_down("#{@name} entering Code")
    super(board_columns)
    generate_code_arr = []
    generate_guessed_code(board_columns, confirmed_values_arr, generate_code_arr)
    generate_code_arr
  end

  private

  def generate_guessed_code(board_columns, confirmed_values_arr, generate_code_arr)
    (0..board_columns).each do |idx|
      if confirmed_values_arr[idx]
        generate_code_arr.push(confirmed_values_arr[idx])
      else
        code = rand(0..9)
        generate_code_arr.push(code)
      end
    end
  end

  def generate_correct_code(generate_code_arr, board_columns)
    (0...board_columns).each do
      code = 0
      loop do
        code = rand(0..9)
        break unless generate_code_arr.any?(code)
      end
      generate_code_arr.push(code)
    end
  end

  def generate_name
    rand(1..999)
  end
end

# Board
class Board
  attr_reader :active_row, :board_columns

  def initialize(board_columns, code_breaker_name, code_maker_name)
    @board_columns = board_columns
    @active_row = 0
    @board_content = Array.new(12)
    @code_breaker_score = 0
    @code_maker_score = 0
    @code_breaker_name = code_breaker_name
    @code_maker_name = code_maker_name
    print_board
    puts "The code breaker chose #{@board_columns} board columns, the above is what the board will look like"
  end

  def update_board(number_arr, clue_arr)
    @board_content[@active_row] = [number_arr, clue_arr]
    @active_row += 1
    print_board
  end

  def update_score(code_breaker_score, code_maker_score)
    @code_breaker_score = code_breaker_score
    @code_maker_score = code_maker_score
    display_player_scores
  end

  def switch_players
    @code_breaker_name, @code_maker_name = @code_maker_name, @code_breaker_name
    @code_breaker_score, @code_maker_score = @code_maker_score, @code_breaker_score
  end

  def print_board
    board = "\n"
    @board_content.each { |row| board += print_row(row) }
    board += print_columns('+---', '+     ')
    board += print_columns('+---', "+\n")
    puts board
  end

  def clear_board
    @active_row = 0
    @board_content = Array.new(12)
  end

  private

  def display_player_scores
    puts "\nPoints are:"
    puts "#{@code_breaker_name}: #{@code_breaker_score} (Code breaker) "
    puts "#{@code_maker_name}: #{@code_maker_score} (Code maker)"
    puts ''
  end

  def print_row(row)
    board = ''
    board += print_columns('+---', '+     ')
    board += print_columns('+---', "+\n")
    board += print_columns('|', '|     ', row.nil? ? nil : row[0], insert_data: true)
    board += print_columns('|', "|\n", row.nil? ? nil : row[1], insert_data: true)
    board
  end

  def print_columns(seperator, trailing, arr = nil, insert_data: false)
    board = ''
    (0...@board_columns.to_i).each do |idx|
      board += seperator
      board += " #{arr.nil? || arr[idx].nil? ? ' ' : arr[idx]} " if insert_data
    end
    board + trailing
  end
end

Mastermind.new
