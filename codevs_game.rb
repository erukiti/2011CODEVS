def debug_log(msg)
  putlog("D: #{msg}") if $debugmode
end

def debug_on
  putlog("debug mode")
  $debugmode = true
end

require 'digest/md5'

  class MapData
    attr_reader :w
    attr_reader :h
    attr_reader :data
    def initialize(w, h, data = nil)
      if data
        @data = data.dup
      else
        @data = Array.new(w * h)
      end
      @w = w
      @h = h
    end

    def fill(data)
      @data.fill(data)
    end

    def [](x, y)
      @data[adrs(x, y)]
    end

    def []=(x, y, data)
      @data[adrs(x, y)] = data
    end

    def adrs(x, y)
      x + y * @w
    end

    def inspect
      result = ''
      (0...@h).each do |y|
        (0...@w).each do |x|
          result += "#{self[x, y].inspect}, "
        end
        result += "\n"
      end
      result
    end

    def hash
      @data.to_s
    end

    def dup
      MapData.new(@w, @h, @data)
    end
  end

  class Map
    attr_reader :mapdata
    attr_reader :start_list

    def w
      @mapdata.w
    end

    def h
      @mapdata.h
    end

    def initialize(w, h, maptext)
      @mapdata = MapData.new(w, h)
      @start_list = []

      y = 0
      maptext.each_line do |line|
        x = 0
        line.each_byte do |ch|
          next if ch.chr == "\n"
          @mapdata[x, y] = ch.chr
          @start_list << [x, y] if ch.chr == 's'
          x += 1
        end
        y += 1
      end

      @least_memo = {}
    end

    MOVE = [[1, 0, 2], [1, -1, 3], [0, -1, 2], [-1, -1, 3], [-1, 0, 2], [-1, 1, 3], [0, 1, 2], [1, 1, 3]]

    def block?(obj)
      obj == '1' || obj == 't'
    end

    def goal?(obj)
      obj == 'g'
    end

    def least_course(x, y, tower_list = [])
      reached = @mapdata.dup
      tower_list.each do |tower|
        reached[tower.x, tower.y] = 't'
      end

      reached[x, y] = '1'

      #hash = reached.hash
      #return @least_memo[hash] if @least_memo[hash]

#p reached
      least_cost = nil

      queue = [[x, y, 0, []]]
      course_list = []
      while queue.size > 0
        new_queue = []
        queue.each do |x, y, cost, course|
          MOVE.each do |move_x, move_y, move_cost|
            new_x = x + move_x
            new_y = y + move_y
            new_cost = cost + move_cost
            new_obj = reached[new_x, new_y]

            next if least_cost && least_cost < new_cost
            next if block?(new_obj)
            next if new_obj.is_a?(Integer) && new_cost >= new_obj
            next if move_cost == 3 && (block?(reached[x, new_y]) || block?(reached[new_x, y])) #ナナメチェック

            new_course = course + [[new_x, new_y]]
            if goal?(new_obj)
              unless course_list[new_cost]
                course_list[new_cost] = new_course
              end
              least_cost = new_cost if !least_cost || least_cost > new_cost
            elsif (!least_cost || least_cost > new_cost)
              new_queue << [new_x, new_y, new_cost, new_course]
              reached[new_x, new_y] = new_cost
            end
          end
        end

        queue = new_queue
      end

      if least_cost
        result = [least_cost, course_list[least_cost]]
      else
        result = [nil, []]
      end
      #@least_memo[reached.hash] = result

      result
    end
  end


  class Enemy
    attr_reader :start_x
    attr_reader :start_y
    attr_reader :spawn_time
    attr_reader :start_life
    attr_reader :move_timecost
    attr_reader :priority
    attr_accessor :course

    def initialize(x, y, spawn_time, life, move_timecost, priority)
      @start_x = x
      @start_y = y
      @spawn_time = spawn_time
      @start_life = life
      @priority = priority
      @move_timecost = move_timecost
    end

    def discovery(map, tower_list = [])
      cost, @course, = map.least_course(@start_x, @start_y, tower_list)
    end
  end

  class Event
    NONE = 0
    MOVE = 1
    DEAD = 2
    GOAL = 3

    attr_reader :enemy
    attr_reader :life
    attr_reader :x
    attr_reader :y
    attr_reader :timing
    attr_reader :type

    def initialize(enemy)
      @enemy = enemy
      @life = enemy.start_life
      @x = enemy.start_x
      @y = enemy.start_y
      @timing = enemy.spawn_time
      @move = 0
      @type = NONE
    end

    def lost?
      @type == GOAL || @type == DEAD
    end

    def dead?
      @life <= 0
    end

    def first?
      @type == NONE
    end

    def goal?
      @move == @enemy.course.size - 1
    end

    def move_timecost
      x, y = @enemy.course[@move]
      if x == @x || y == @y
        @enemy.move_timecost
      else
        @enemy.move_timecost * 14 / 10
      end
    end

    def plan
      return nil if lost?

      return @timing if first?
      return @timing if dead?
      return @timing + move_timecost
    end

    def move
      if first?
        @type = MOVE
      elsif goal?
        @timing += move_timecost
        @x, @y = @enemy.course[@move]
        @type = GOAL
      else
        @timing += move_timecost
        @x, @y = @enemy.course[@move]
        @move += 1
      end
      debug_log "move [#{@enemy.priority}] #{@x},#{@y}"
      true
    end

    def dead
      @type = DEAD
    end

    def damage(power, timing)
      @life -= power
      if dead?
        @timing = timing
      end
    end
  end

  class Tower
    RAPID = 0
    ATACK = 1
    FREEZE = 2

    def self.buildable(type, money, level = -1)
      case type
      when RAPID
        base_cost = 10
      when ATACK
        base_cost = 15
      when FREEZE
        base_cost = 20
      end

      cost = 0
      while level < 4
        money -= base_cost * (level + 1 + 1)
        break if money < 0
        level += 1
        cost += base_cost * (level + 1)
      end
      [level, cost]
    end

attr_reader :timing
attr_reader :power
attr_reader :charge
attr_reader :level
attr_reader :x
attr_reader :y
attr_reader :type

    def clear
      @timing = 1
      @atack_queue = []
    end

    def initialize(x, y, level, type)
      @x = x
      @y = y
      @type = type
      @level = level

      case type
      when RAPID
        @range = 4.0 + level
        @charge = 10 - level * 2 + 1
        @power = 10 * (1 + level)
      when ATACK
        @range = 5.0 + level
        @charge = 20 - level * 2 + 1
        @power = 20 * (1 + level)
      when FREEZE
        @range = 2.0 + level
        @charge = 20 + 1
        @power = 3 * (1 + level)
      end

      @timing = 1
      @atack_queue = []
    end

    def self.range?(x1, y1, x2, y2, type, level)
      case type
      when RAPID
        range = 4.0 + level
      when ATACK
        range = 5.0 + level
      when FREEZE
        range = 2.0 + level
      end

      Math.sqrt((x1 - x2) ** 2 + (y1 - y2) ** 2) <= range
    end

    def range?(x, y)
      Math.sqrt((@x - x) ** 2 + (@y - y) ** 2) <= @range
    end

    def atack_queue
      @atack_queue
    end

    def atackable?(event)
      range?(event.x, event.y) && event.type != Event::DEAD
    end

    def event_check(event_list)
#debug_log "#{object_id} event_check #{@atack_queue.size}"
      add_queue = []
      event_list.each do |event|
        ev = @atack_queue.find {|ev| ev.enemy == event.enemy}
        if ev
          unless atackable?(event)
            debug_log "#{object_id} #{x},#{y} remove [#{ev.enemy.priority}] #{event.x},#{event.y}"
            @atack_queue.delete(ev) 
          end
        else
          if atackable?(event)
            add_queue << event 
            debug_log "#{object_id} #{x},#{y} add [#{event.enemy.priority}] #{event.x},#{event.y}"
          end
        end
      end

      @atack_queue += add_queue.sort {|a, b| a.enemy.priority <=> b.enemy.priority}.sort {|a, b| a.enemy.spawn_time <=> b.enemy.spawn_time}
    end

    def plan(timing)
      if @atack_queue.size == 0
        nil
      elsif timing >= @timing
        timing
      else
        @timing
      end

    end

    def atack?(current_timing)
      timing <= current_timing && atack_queue.size > 0
    end

    def atack(timing)
if plan(timing) != timing
  putlog "ERROR! #{plan(timing)} != #{timing}"
end

      @atack_queue[0].damage(@power, timing)
      @timing = timing + @charge
debug_log "#{object_id} #{x},#{y} atack! #{timing}, [#{@atack_queue[0].enemy.priority}] #{@atack_queue[0].x},#{@atack_queue[0].y} life:#{@atack_queue[0].life}"
    end
  end

  class EventDispatcher
    attr_reader :current_timing
    attr_reader :goaled
    attr_reader :gain_money
    attr_reader :event_list

    def initialize(enemy_list, tower_list)
      @current_timing = 0
      @goaled = 0
      @goaled_enemy = []
      @gain_money = 0

      @event_list = []
      enemy_list.each do |enemy|
        @event_list << Event.new(enemy)
      end

      @tower_list = tower_list
      tower_list.each do |tower|
        tower.clear
      end
    end

    def top
      next_plan = nil
      @event_list.each do |event|
        next_plan = event.plan if next_plan == nil || (event.plan && next_plan > event.plan)
      end
      next_plan
    end

    def get
      result = []

      @event_list.each do |event|
        result << event if @current_timing == event.timing
      end
      result
    end

    def top_tower
      next_plan = nil
      @tower_list.each do |tower|
        plan = tower.plan(@current_timing)
        next_plan = plan if next_plan == nil || (plan && next_plan > plan)
      end
      next_plan
    end

    def next_frame
      next_event = top
      next_tower = top_tower

      if next_event == nil
        putlog "ERROR: #{@current_timing} next_event == nil"
        putlog @event_list.inspect
        return false
      end
#p "1: #{@current_timing}, #{next_event}, #{next_tower}"
      if next_tower == nil || next_event <= next_tower
        @current_timing = next_event
#p "move: #{@current_timing}"
        @event_list.each do |event|
          if event.plan == @current_timing
            event.move
          end
        end

        @tower_list.each do |tower|
          tower.event_check(get)
        end
#p "C: #{@current_timing}"
        next_tower = top_tower || @current_timing
      end

#p "2: #{@current_timing}, #{next_event}, #{next_tower}"
      if @current_timing == next_tower || next_tower <= next_event
        @current_timing = next_tower
        @tower_list.each do |tower|
#p "To: #{@current_timing}: #{tower.timing}"
          tower.atack(@current_timing) if tower.atack?(@current_timing)
        end

        if @current_timing == top
          @event_list.each do |event|
            #if event.plan == @current_timing
            if event.life <= 0
              event.dead
              gain_money = (event.enemy.start_life - (@current_timing - event.enemy.spawn_time)) / 10
              @gain_money += gain_money if gain_money > 0
              debug_log "defeated: #{@current_timing} #{event.enemy.start_x}, #{event.enemy.start_y} #{event.enemy.spawn_time} #{event.enemy.start_life}"
              debug_log "gain_money: #{gain_money}" if gain_money > 0
              putlog "ERROR! #{event.type}" if event.type != Event::DEAD
              @tower_list.each do |tower|
                tower.event_check(get)
              end
              @event_list.delete(event)
            end
          end
        end
      end

      @event_list.each do |event|
        if event.type == Event::GOAL
          if event.life > 0
            debug_log "goaled: #{current_timing}"
            @goaled += 1 
            @goaled_enemy << event.enemy
          end
          @event_list.delete(event)
        end
      end


      @event_list.size > 0
    end

    def simulate(is_abort = false)
@tower_list.each do |tower|
  debug_log "Tower: #{tower.object_id} #{tower.x},#{tower.y} #{tower.level} #{tower.type}"
end

@event_list.each do |event|
  debug_log "course: [#{event.enemy.priority}] #{event.enemy.course.inspect}"
end

      while next_frame
debug_log "#{@current_timing}\n"
        break if @goaled > 2 && is_abort
      end
      [@goaled, @gain_money, @goaled_enemy]
    end
    

def debug
  puts "debug #{@current_timing}"
  @event_list.each do |ev|
    p ev
    p ev.plan
  end
  puts ""
end

    end

class Game
  attr_reader :life
  attr_reader :money
  attr_reader :tower_list

  def initialize(life = 10, money = 100)
    @map = nil
    @w = nil
    @h = nil
    @life = life
    @money = money
    @tower_list = []
    @enemy_list = []
    @action_list = []
    @is_secondhalf = false
  end

  def secondhalf
    @is_secondhalf = true
    @money /= 2
  end

  def new_map(w, h, maptext)
    @w = w
    @h = h
    @map = Map.new(w, h, maptext)
    @enemy_list = []
    @tower_list = []
    @action_list = []
  end

  def new_wave(life, money)
    @action_list = []
    @enemy_list = []
    if @life != nil
      putlog "ERROR: life #{@life} != #{life}" if @life != life
      putlog "ERROR: money #{@money} != #{money}" if @money != money
    end
    @money = money
    @life = life
  end

  def set_enemy(x, y, spawn_time, life, move_timecost)
    enemy = Enemy.new(x, y, spawn_time, life, move_timecost, @enemy_list.size)
    putlog "enemy: #{x}, #{y} : #{spawn_time}, #{life}, #{move_timecost}"
    @enemy_list << enemy
  end

  def set_tower(tower_x, tower_y, tower_level, tower_type)
    putlog "set tower: #{tower_x},#{tower_y} tower_level tower_type"
    tower = @tower_list.find {|tower| tower.x == tower_x && tower.y == tower_y}
    if tower
      @tower_list.delete(tower)
    end
    @tower_list << Tower.new(tower_x, tower_y, tower_level, tower_type)
  end

  def check_tower_list(tower_list)
    tower_list_maybe = []
    @tower_list.each do |tower|
      tower_list_maybe << [tower.x, tower.y, tower.level, tower.type]
    end

    if (tower_list.sort{|a, b| a[0] <=> b[0]}.sort{|a, b| a[1] <=> b[1]}) != (tower_list_maybe.sort{|a, b| a[0] <=> b[0]}.sort{|a, b| a[1] <=> b[1]})
      putlog "ERROR: check_tower_list"
      @tower_list = []
      tower_list.each do |x, y, level, type|
        @tower_list << Tower.new(x, y, level, type)
      end
    end
  end

  def simulate(tower_list = @tower_list, is_abort = false)
    putlog '===== simulate'
    goaled, gain_money, goaled_enemy= EventDispatcher.new(@enemy_list, tower_list).simulate(is_abort)
    debug_log '====='

    [goaled, gain_money, goaled_enemy]
  end

  def debug_action(action_list)
    @action_list = action_list
  end

  def compute
    # @action_list を設定済みであること


    @tower_list.each do |tower|
      putlog "T: #{tower.x},#{tower.y} #{tower.level} #{tower.type}"
    end

    @enemy_list.each do |enemy|
      enemy.discovery(@map, @tower_list)
    end

    goaled, gain_money, goaled_enemy = simulate
    @life -= goaled
    @money += gain_money unless @is_secondhalf

    @action_list
  end

end

  class Think
    attr_reader :action_list
    attr_reader :tower_list
    attr_reader :money
    def initialize(map, money, enemy_list = [], tower_list = [])
      @map = map
      @money = money
      @enemy_list = enemy_list
      @tower_list = tower_list
      @action_list = []
      @dont_update = false

      # 最初の map でしかおそらく使わない
      @tower_list.each do |tower|
        if tower.type == Tower::RAPID && tower.level != 4
          update, cost = Tower.buildable(Tower::RAPID, @money, tower.level)
          if update > tower.level
            @action_list << "#{tower.x} #{tower.y} #{update} #{tower.type}"
            set_tower(tower.x, tower.y, update, tower.type)
            @money -= cost
            debug_log "tower update: #{tower.x} #{tower.y} #{update} #{tower.type}"
            debug_log "money: #{@money}"
          else
            @dont_update = true
          end
        end
      end
    end

    def set_tower(tower_x, tower_y, tower_level, tower_type)
      tower = @tower_list.find {|tower| tower.x == tower_x && tower.y == tower_y}
      if tower
        @tower_list.delete(tower)
      end
      @tower_list << Tower.new(tower_x, tower_y, tower_level, tower_type)
    end


    def disturb(enemy)
#p @tower_list.size
#debug_log "disturb #{enemy.priority}"
      least_cost, least_course = @map.least_course(enemy.start_x, enemy.start_y, @tower_list)
#p least_course
      disturb_list = []
      close_list = []
      least_course.each do |x, y|
        if @map.mapdata[x, y] == '0'
          cost, c = @map.least_course(enemy.start_x, enemy.start_y, @tower_list + [Tower.new(x, y, Tower::RAPID, 0)])
#p "#{x}, #{y} : #{c.inspect}"
          disturb_list << [x, y, cost - least_cost] if cost && cost > least_cost
          close_list << [x, y] unless cost
        end
      end
      [disturb_list, close_list]
    end

    def score_rapid(enemy_list = @enemy_list)
      return false if @dont_update

debug_log "score_rapid"

      #link_map = @map.get_link_map
      score_map = MapData.new(@map.w, @map.h)
      score_map.fill(0.0)
      tower_level, cost = Tower.buildable(Tower::RAPID, @money)
      return false if tower_level < 0

debug_log "disturb"

      course_list = []
      memo = []
      enemy_list.each do |enemy|
        if !memo[enemy.start_x + enemy.start_y * @map.w]
          disturb_list, close_list = disturb(enemy)
          disturb_list.each do |x, y, costup|
            score_map[x, y] += 1.0 + (costup / 10.0) if score_map[x, y]
          end
          close_list.each do |x, y|
            score_map[x, y] = nil
          end
          enemy.discovery(@map, @tower_list)
          memo[enemy.start_x + enemy.start_y * @map.w] = enemy.course
        end

        course_list << memo[enemy.start_x + enemy.start_y * @map.w]
      end

      atack_max = 0
      course_list.each do |course|
        atack_max += course.size
      end

debug_log "rangemap"

      (1...@map.h - 1).each do |y|
        (1...@map.w - 1).each do |x|
          next if @map.mapdata[x, y] != '0' || @tower_list.find{|tower| tower.x == x && tower.y == y}

          atack_point = 0
          course_list.each do |course|
            course.each do |x1, y1|
              atack_point += 1 if Tower.range?(x, y, x1, y1, Tower::RAPID, tower_level)
            end
          end
          score_map[x, y] += atack_point / atack_max if score_map[x, y]
        end
      end

      result = nil
      score_max = 0
      (1...@map.h - 1).each do |y|
        (1...@map.w - 1).each do |x|
          if score_map[x, y] && score_map[x, y] > score_max
            score_max = score_map[x, y]
            result = [x, y]
          end
        end
      end

debug_log "score_map\n#{score_map.inspect}"

      if result
        @action_list << "#{result[0]} #{result[1]} #{tower_level} #{Tower::RAPID}"
        set_tower(result[0], result[1], tower_level, Tower::RAPID)
        @money -= cost
putlog "cost: #{cost}"
        putlog "tower: #{result[0]} #{result[1]} #{tower_level} #{Tower::RAPID}"
        putlog "money: #{@money}"
        return true
      else
        return false
      end
      
    end
  end

  # simulate で撃ち漏らした敵の場合のスコアをもうちょっといじる
  # というか、倒せた敵の通り道やレンジに対するスコアを下げる

