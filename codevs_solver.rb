#! /usr/bin/env ruby

require File.dirname(__FILE__) + '/codevs_game.rb'

class Game
  def think
    think_rapid
  end

  def think_rapid
    enemy_list = @enemy_list
    thinker = Think.new(@map, @money, @enemy_list, @tower_list)

    @enemy_list.each do |enemy|
      debug_log "enemy: [#{enemy.priority}]: #{enemy.start_x},#{enemy.start_y} #{enemy.spawn_time} #{enemy.start_life}"
    end

    simulated = 0
    loop do 
      goaled_enemy = enemy_list
      if thinker.tower_list.size > 0
        @enemy_list.each do |enemy|
          enemy.discovery(@map, thinker.tower_list)
        end
        goaled, gain_money, goaled_enemy = simulate(thinker.tower_list, true)
        simulated += 1
        break if goaled == 0
      end

      break unless thinker.score_rapid(enemy_list)
      enemy_list = goaled_enemy
    end

    putlog "simulated #{simulated}"

    @money = thinker.money
    @action_list = thinker.action_list
  end
end

def putlog(msg)
  $log << "#{Time.now.strftime '%H:%M:%S'}.#{Time.now.usec/1000} #{msg}\n"
  $log.flush
end

def getline
  buf = gets
  unless buf
    putlog "end" 
    #putlog caller.first.inspect
    exit
  end
  $stdin_txt << buf
  $stdin_txt.flush
  buf.strip
end

def getlist(n)
  list = getline.split(/ /).map { |x| x.to_i}
  if list.size != n
    putlog "illegal lists #{list.size} != #{n}"
    putlog caller.first.inspect
    exit(1)
  end
  if n == 1
    list[0]
  else
    list
  end
end

def waitend
  line = getline
  if line != "END"
    putlog "illegal END '#{line}'"
    putlog caller.first.inspect
  end
end

def answer(action_list)
  msg = "#{action_list.size}\n"
  action_list.each do |action|
    msg += "#{action}\n"
  end

  print msg
  STDOUT.flush
  putlog "answer:\n#{msg}"
end

$log = File.open("log.txt", "a")
$stdin_txt = File.open("stdin.txt", "w")

putlog "---- start #{Time.now.strftime '%Y-%m-%d'}"

game = Game.new

p_num = 0
max_map = getlist 1
putlog "map: #{max_map}"

debug_on if max_map != 80

(1..max_map).each do |mapnum|
  game.secondhalf if mapnum == 41

  w, h = getlist 2

  maptext = ""
  (0...h).each do
    maptext << "#{getline}\n"
  end

  putlog "#{mapnum}: #{w} x #{h}\n#{maptext}"

  game.new_map(w, h, maptext)

  max_level = getlist 1
  putlog "level: #{max_level}"
  waitend

  (1..max_level).each do |wave|
    life, money, max_tower, max_enemy = getlist 4
    putlog "wave #{mapnum}-#{wave}: #{life}life #{money}money"

    game.new_wave(life, money)

    tower_list = []
    (0...max_tower).each do
      tower_list << getlist(4)
    end
    game.check_tower_list tower_list

    (0...max_enemy).each do
      x, y, spawn_time, enemy_life, move_time = getlist 5
      game.set_enemy x, y, spawn_time, enemy_life, move_time
    end
    waitend

    game.think
    answer game.compute
  end
end
