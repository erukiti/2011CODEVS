#! /usr/bin/env ruby

require 'test/unit'
require File.dirname(__FILE__) + '/codevs_game.rb'


class TC_Tower < Test::Unit::TestCase
  class MockEvent
    attr_reader :timing, :type, :enemy, :x, :y
    def initialize(timing, type, enemy, x, y)
      @timing = timing
      @type = type
      @enemy = enemy
      @x = x
      @y = y
    end
  end

  def test_range
    tower = Tower.new(1, 1, 0, Tower::FREEZE)
    assert_equal(tower.range?(1, 1), true)
    assert_equal(tower.range?(1, 2), true)
    assert_equal(tower.range?(1, 3), true)
    assert_equal(tower.range?(2, 2), true)
    assert_equal(tower.range?(2, 3), false)
    assert_equal(tower.range?(3, 3), false)

    tower = Tower.new(1, 1, 0, Tower::RAPID)
    assert_equal(tower.range?(1, 5), true)
    assert_equal(tower.range?(2, 5), false)
    assert_equal(tower.range?(2, 4), true)
    assert_equal(tower.range?(3, 4), true)
    assert_equal(tower.range?(4, 4), false)
  end

  def test_queue

    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 1, 5)] #射程圏内
    assert_equal(tower.atack_queue.size, 1)
    assert_equal(tower.atack_queue[0].enemy, enemy1)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 2, 4)] #射程圏内
    assert_equal(tower.atack_queue.size, 1)
    assert_equal(tower.atack_queue[0].enemy, enemy1)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 2, 5)] #射程圏外
    assert_equal(tower.atack_queue.size, 0)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 4, 4)] #射程圏外
    assert_equal(tower.atack_queue.size, 0)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 1, 5)] #射程圏内
    assert_equal(tower.atack_queue.size, 1)
    assert_equal(tower.atack_queue[0].enemy, enemy1)

    tower.event_check [MockEvent.new(1, Event::DEAD, enemy1, 1, 5)] #倒した
    assert_equal(tower.atack_queue.size, 0)

    tower.event_check [MockEvent.new(1, Event::DEAD, enemy1, 1, 5)] #倒した
    assert_equal(tower.atack_queue.size, 0)


    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy2 = Enemy.new(1, 3, 10, 50, 15, 2)
    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 1, 5), MockEvent.new(1, Event::MOVE, enemy2, 2, 5)] #射程圏内 & 射程圏外
    assert_equal(tower.atack_queue.size, 1)
    assert_equal(tower.atack_queue[0].enemy, enemy1)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy2, 1, 5), MockEvent.new(1, Event::MOVE, enemy1, 1, 5)] #射程圏内 & 射程圏内
    assert_equal(tower.atack_queue.size, 2)
    assert_equal(tower.atack_queue[0].enemy, enemy1)
    assert_equal(tower.atack_queue[1].enemy, enemy2)

    tower.event_check [MockEvent.new(1, Event::MOVE, enemy1, 1, 5), MockEvent.new(1, Event::MOVE, enemy2, 1, 5)] #射程圏内 & 射程圏内
    assert_equal(tower.atack_queue.size, 2)
    assert_equal(tower.atack_queue[0].enemy, enemy1)
    assert_equal(tower.atack_queue[1].enemy, enemy2)

    tower.event_check [MockEvent.new(1, Event::DEAD, enemy2, 1, 5)] #敵一人死亡
    assert_equal(tower.atack_queue.size, 1)
    assert_equal(tower.atack_queue[0].enemy, enemy1)

    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy3 = Enemy.new(1, 3, 10, 40, 20, 3)
    enemy4 = Enemy.new(1, 3, 5, 40, 20, 4)
    tower.event_check [
      MockEvent.new(1, Event::MOVE, enemy4, 1, 5),
      MockEvent.new(1, Event::MOVE, enemy1, 1, 5), 
      MockEvent.new(1, Event::MOVE, enemy2, 1, 5),
      MockEvent.new(1, Event::MOVE, enemy3, 1, 5)
    ] #射程圏内 & 射程圏外
    assert_equal(tower.atack_queue.size, 4)
    assert_equal(tower.atack_queue[0].enemy, enemy1)
    assert_equal(tower.atack_queue[1].enemy, enemy4)
    assert_equal(tower.atack_queue[2].enemy, enemy2)
    assert_equal(tower.atack_queue[3].enemy, enemy3)


  end
end

class TC_Think < Test::Unit::TestCase
  def test_disturb
    map = Map.new(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s00001
1000001
1111111
EOF
)

    think = Think.new(map, 100)
    disturb_list, close_list = think.disturb(Enemy.new(1, 3, 5, 40, 20, 1))
    assert_equal(disturb_list, [[2, 3, 3], [3, 3, 2], [4, 3, 3]])
    assert_equal(close_list, [])

    think = Think.new(map, 100)
    disturb_list, close_list = think.disturb(Enemy.new(1, 4, 5, 40, 20, 1))
    assert_equal(disturb_list, [[2, 4, 1]])
    assert_equal(close_list, [])

    think = Think.new(map, 100, [], [Tower.new(2, 4, 0, 1)])
    disturb_list, close_list = think.disturb(Enemy.new(1, 4, 5, 40, 20, 1))
    assert_equal(disturb_list, [[2, 3, 2], [3, 3, 2], [4, 3, 3]])
    assert_equal(close_list, [])

    think = Think.new(map, 100, [], [Tower.new(2, 4, 0, 1), Tower.new(2, 3, 0, 1)])
    disturb_list, close_list = think.disturb(Enemy.new(1, 4, 5, 40, 20, 1))
    assert_equal(disturb_list, [[1, 5, 1], [2, 5, 1], [3, 5, 1], [4, 4, 1]])
    assert_equal(close_list, [])

    think = Think.new(map, 100, [], [Tower.new(2, 4, 0, 1), Tower.new(2, 3, 0, 1), Tower.new(2, 2, 0, 1)])
    disturb_list, close_list = think.disturb(Enemy.new(1, 4, 5, 40, 20, 1))
    assert_equal(disturb_list, [[1, 5, 4], [2, 5, 4], [3, 5, 4], [4, 4, 2]])
    assert_equal(close_list, [])

    think = Think.new(map, 100, [], [Tower.new(2, 4, 0, 1), Tower.new(2, 3, 0, 1), Tower.new(2, 2, 0, 1), Tower.new(2, 5, 0, 1)])
    disturb_list, close_list = think.disturb(Enemy.new(1, 4, 5, 40, 20, 1))
    assert_equal(disturb_list, [[4, 2, 2]])
    assert_equal(close_list, [[1, 1], [2, 1], [3, 1]])

    map = Map.new(7, 3, <<EOF
1111111
1s000g1
1111111
EOF
)
    think = Think.new(map, 100)
    disturb_list, close_list = think.disturb(Enemy.new(1, 1, 5, 40, 20, 1))
    assert_equal(disturb_list.size, 0)
    assert_equal(close_list, [[2, 1], [3, 1], [4, 1]])
  end

  def test_score_rapid
    map = Map.new(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s00001
1000001
1111111
EOF
)
    think = Think.new(map, 100, [Enemy.new(1, 3, 5, 40, 20, 1)])
    assert_not_equal(think.score_rapid, nil)
    # テストどうしよう？

  end
end




class TC_EventDispatcher < Test::Unit::TestCase
  def test_next_frame
    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1], [tower])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 5)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 30)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 16)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 25)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 27)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 38)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)


    # 敵が複数
    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    enemy2 = Enemy.new(1, 3, 8, 80, 10, 1)
    enemy2.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1, enemy2], [tower])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 5)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 30)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 1)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 8)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 30)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 1)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 16)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 1)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 18)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 2)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 25)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 2)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 27)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 2)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 28)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 3)
    assert_equal(event_list[1].y, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 38)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 80)
    assert_equal(event_list[0].x, 4)
    assert_equal(event_list[0].y, 3)
	assert_equal(event_dispatcher.gain_money, 0)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 48)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.goaled, 1)
	assert_equal(event_dispatcher.gain_money, 0)

    #敵とタワーが複数
    tower1 = Tower.new(1, 1, 0, Tower::RAPID)
    tower2 = Tower.new(1, 1, 1, Tower::RAPID) # charge = 9, power = 20
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    enemy2 = Enemy.new(1, 3, 8, 80, 10, 1)
    enemy2.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1, enemy2], [tower1, tower2])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 5)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 1)
    assert_equal(event_list[1].y, 3)
    # tower1 = 16, tower2 = 14, enemy1 = 25, enemy2 = 8

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 8)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    assert_equal(event_list[1].life, 80)
    assert_equal(event_list[1].x, 1)
    assert_equal(event_list[1].y, 3)
    # tower1 = 16, tower2 = 14, enemy1 = 25, enemy2 = 18

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 14)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 80)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    # tower1 = 16, tower2 = 23, enemy2 = 18
    assert_equal(event_dispatcher.gain_money, 3)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 16)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 70)
    assert_equal(event_list[0].x, 1)
    assert_equal(event_list[0].y, 3)
    # tower1 = 27, tower2 = 23, enemy2 = 18

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 18)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 70)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    # tower1 = 27, tower2 = 23, enemy2 = 28

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 23)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 50)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    # tower1 = 27, tower2 = 32, enemy2 = 28

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 27)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 40)
    assert_equal(event_list[0].x, 2)
    assert_equal(event_list[0].y, 3)
    # tower1 = 38, tower2 = 32, enemy2 = 28

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 28)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 40)
    assert_equal(event_list[0].x, 3)
    assert_equal(event_list[0].y, 3)
    # tower1 = 38, tower2 = 32, enemy2 = 38

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 32)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 20)
    assert_equal(event_list[0].x, 3)
    assert_equal(event_list[0].y, 3)
    # tower1 = 38, tower2 = 41, enemy2 = 38

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 38)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_list[0].life, 10)
    assert_equal(event_list[0].x, 4)
    assert_equal(event_list[0].y, 3)
    # tower1 = 49, tower2 = 41, enemy2 = 48

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 41)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.gain_money, 7)

    #ゴールした瞬間に倒すケース
    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 1, 20, 11, 1)
    enemy1.course = [[2, 3]]
    event_dispatcher = EventDispatcher.new([enemy1], [tower])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 1)
    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 12)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.goaled, 0)
    assert_equal(event_dispatcher.gain_money, 0)
    
    #ゴールした瞬間に倒せなかったケース
    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 1, 30, 11, 1)
    enemy1.course = [[2, 3]]
    event_dispatcher = EventDispatcher.new([enemy1], [tower])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 1)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 12)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.goaled, 1)
    assert_equal(event_dispatcher.gain_money, 0)

    tower = Tower.new(2, 4, 3, Tower::RAPID)
    enemy1 = Enemy.new(1, 4, 2, 54, 116, 1)
    enemy2 = Enemy.new(1, 4, 11, 82, 68, 2)
    enemy3 = Enemy.new(1, 3, 17, 77, 82, 3)
    enemy1.course = [[1, 3], [2, 3], [3, 3], [4, 3], [5,3]]
    enemy2.course = [[1, 3], [2, 3], [3, 3], [4, 3], [5,3]]
    enemy3.course = [[2, 3], [3, 3], [4, 3], [5, 3]]
    event_dispatcher = EventDispatcher.new([enemy1, enemy2, enemy3], [tower])

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 2)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 14)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 7)
    event_list = event_dispatcher.event_list
    assert_equal(event_dispatcher.gain_money, 4)
    assert_equal(event_list.size, 2)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 11)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 12)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 42)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 17)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 2)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 22)
    assert_equal(event_dispatcher.gain_money, 11)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 27)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 37)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 32)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.gain_money, 17)

    #
    map = Map.new(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s00001
1000001
1111111
EOF
)
    tower1 = Tower.new(2, 4, 4, Tower::RAPID)
    tower2 = Tower.new(4, 3, 4, Tower::RAPID)
    enemy1  = Enemy.new(1, 2, 16, 259, 113, 1)
    enemy2  = Enemy.new(1, 3, 19, 191, 94, 2)
    enemy3  = Enemy.new(1, 4, 17, 249, 87, 3)
    enemy4  = Enemy.new(1, 2, 23, 219, 22, 4)
    enemy5  = Enemy.new(1, 4, 29, 272, 86, 5)
    enemy6  = Enemy.new(1, 3, 17, 197, 112, 6)
    enemy7  = Enemy.new(1, 3, 16, 248, 23, 7)
    enemy8  = Enemy.new(1, 2, 15, 248, 80, 8)
    enemy9  = Enemy.new(1, 2, 19, 245, 26, 9)
    enemy10 = Enemy.new(1, 3, 7,  268, 25, 10)
    enemy_list = [enemy1, enemy2, enemy3, enemy4, enemy5, enemy6, enemy7, enemy8, enemy9, enemy10]
    tower_list = [tower1, tower2]
    enemy_list.each do |enemy|
      enemy.discovery(map, tower_list)
    end
    event_dispatcher = EventDispatcher.new(enemy_list, tower_list)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 7)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[9].life, 168)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 10)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[9].life, 68)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 13)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 9)
    assert_equal(event_dispatcher.gain_money, 26)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 15)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 16)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[7].life, 148)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 17)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 19)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[7].life, 48)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 22)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 8)
    assert_equal(event_dispatcher.gain_money, 50)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 23)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 25)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 159)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 28)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 59)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 29)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 31)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 7)
    assert_equal(event_dispatcher.gain_money, 74)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 34)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[5].life, 148)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 37)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[5].life, 48)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 39)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 40)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 6)
    assert_equal(event_dispatcher.gain_money, 96)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 43)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[1].life, 149)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 45)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 46)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[1].life, 49)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 49)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 5)
    assert_equal(event_dispatcher.gain_money, 117)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 52)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[3].life, 97)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 55)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 4)
    assert_equal(event_dispatcher.gain_money, 132)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 58)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 91)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 61)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 3)
    assert_equal(event_dispatcher.gain_money, 146)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 64)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[2].life, 145)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 67)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[2].life, 45)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 70)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 2)
    assert_equal(event_dispatcher.gain_money, 165)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 73)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 119)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 76)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 19)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 79)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 1)
    assert_equal(event_dispatcher.gain_money, 181)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 82)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 172)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 85)
    event_list = event_dispatcher.event_list
    assert_equal(event_list[0].life, 72)

    event_dispatcher.next_frame
    assert_equal(event_dispatcher.current_timing, 88)
    event_list = event_dispatcher.event_list
    assert_equal(event_list.size, 0)
    assert_equal(event_dispatcher.gain_money, 202)
    assert_equal(event_dispatcher.goaled, 0)

    #
    
    map = Map.new(36, 24, <<EOF
111111111111111111111111111111111111
1100000000000100100g000000g000001001
1000001100001000010000101010001g0001
10100001g000101000000001000000000001
110000000010001000001000000000000101
1g0010010100000000s01000000000000011
110000010010100000010110000001101001
100101000101100000000001101010110001
10s000000000000010000100000000000111
1010001g0010s00000000000ss0100100011
10001000000001000000s000110010000101
101000100100001010001000010000110001
110001000000000101000s01010010000001
101000000101s10000100010000000000001
1001000001100s0000001000000000000001
10s00000000000100000000100000000g001
100s10000000000000g00010s01000000101
1100000g0110101000100001100000001001
101000010g00100110g00000100001000011
1000001000000000001100001010010g0101
101000000000000000001g00100010000001
100000000110000000011000000001000011
10100000s000001000111010010110000001
111111111111111111111111111111111111
EOF
)
    tower1  = Tower.new( 6, 17, 4, Tower::RAPID)
    tower2  = Tower.new(25,  8, 4, Tower::RAPID)
    tower3  = Tower.new(14, 14, 4, Tower::RAPID)
    tower4  = Tower.new( 7, 16, 4, Tower::RAPID)
    tower5  = Tower.new( 2,  5, 4, Tower::RAPID)
    tower6  = Tower.new(25, 15, 4, Tower::RAPID)
    tower7  = Tower.new( 3, 15, 4, Tower::RAPID)
    tower8  = Tower.new(19,  2, 4, Tower::RAPID)
    tower9  = Tower.new(22, 14, 4, Tower::RAPID)
    tower10 = Tower.new(25, 16, 4, Tower::RAPID)
 
    enemy1  = Enemy.new(24, 16,  1, 1172,  59, 1)  #[[25, 15], [26, 15], [27, 15], [28, 15], [29, 15], [30, 15], [31, 15], [32, 15]]
    enemy2  = Enemy.new( 2,  8,  5, 1174,  63, 2)  #[[2, 7], [2, 6], [2, 5], [1, 5]]
    enemy3  = Enemy.new(24, 16, 28, 1185, 112, 3)  #[[25, 15], [26, 15], [27, 15], [28, 15], [29, 15], [30, 15], [31, 15], [32, 15]]
    enemy4  = Enemy.new(12,  9, 23, 1124,  60, 4)  #[[11, 8], [10, 8], [9, 8], [8, 8], [7, 9]]
    enemy5  = Enemy.new(12,  9, 10, 1194, 116, 5)  #[[11, 8], [10, 8], [9, 8], [8, 8], [7, 9]]
    enemy6  = Enemy.new(12,  9, 24, 1183,  85, 6)  #[[11, 8], [10, 8], [9, 8], [8, 8], [7, 9]]
    enemy7  = Enemy.new(12,  9, 30, 1152,  23, 7)  #[[11, 8], [10, 8], [9, 8], [8, 8], [7, 9]]
    enemy8  = Enemy.new(24, 16, 12, 1110,  88, 8)  #[[25, 15], [26, 15], [27, 15], [28, 15], [29, 15], [30, 15], [31, 15], [32, 15]]
    enemy9  = Enemy.new(18,  5,  4, 1187,  90, 9)  #[[19, 4], [19, 3], [19, 2], [19, 1]]
    enemy10 = Enemy.new(21, 12,  4, 1106,  80, 10) #[[20, 12], [19, 13], [19, 14], [18, 15], [18, 16]]
    enemy11 = Enemy.new(24, 16, 23, 1158,  30, 11) #[[25, 15], [26, 15], [27, 15], [28, 15], [29, 15], [30, 15], [31, 15], [32, 15]]

    enemy_list = [enemy1, enemy2, enemy3, enemy4, enemy5, enemy6, enemy7, enemy8, enemy9, enemy10, enemy11]
    tower_list = [tower1, tower2, tower3, tower4, tower5, tower6, tower7, tower8, tower9, tower10]
    enemy_list.each do |enemy|
      enemy.discovery(map, tower_list)
    end
    event_dispatcher = EventDispatcher.new(enemy_list, tower_list)

    event_dispatcher.next_frame
#    assert_equal(event_dispatcher.current_timing, 7)
#    event_list = event_dispatcher.event_list
#    assert_equal(event_list[9].life, 168)

  end

  def test_simulate
    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1], [tower])
    goaled, gain_money, goaled_enemy = event_dispatcher.simulate
    assert_equal(goaled, 0)
    assert_equal(gain_money, 0)

    tower = Tower.new(1, 1, 0, Tower::RAPID)
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    enemy2 = Enemy.new(1, 3, 8, 80, 10, 1)
    enemy2.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1, enemy2], [tower])
    goaled, gain_money, goaled_enemy = event_dispatcher.simulate
    assert_equal(goaled, 1)
    assert_equal(gain_money, 0)

    tower1 = Tower.new(1, 1, 0, Tower::RAPID)
    tower2 = Tower.new(1, 1, 1, Tower::RAPID) # charge = 9, power = 20
    enemy1 = Enemy.new(1, 3, 5, 40, 20, 1)
    enemy1.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    enemy2 = Enemy.new(1, 3, 8, 80, 10, 1)
    enemy2.course = [[2, 3], [3, 3], [4, 3], [5,3]]
    event_dispatcher = EventDispatcher.new([enemy1, enemy2], [tower1, tower2])
    goaled, gain_money, goaled_enemy = event_dispatcher.simulate
    assert_equal(goaled, 0)
    assert_equal(gain_money, 7)
  end
end

class TC_Tower < Test::Unit::TestCase
  def test_buildable
    assert_equal(Tower.buildable(Tower::RAPID, 9), [-1, 0])
    assert_equal(Tower.buildable(Tower::RAPID, 10), [0, 10])
    assert_equal(Tower.buildable(Tower::RAPID, 11), [0, 10])
    assert_equal(Tower.buildable(Tower::RAPID, 29), [0, 10])
    assert_equal(Tower.buildable(Tower::RAPID, 30), [1, 30])
    assert_equal(Tower.buildable(Tower::RAPID, 31), [1, 30])
    assert_equal(Tower.buildable(Tower::RAPID, 59), [1, 30])
    assert_equal(Tower.buildable(Tower::RAPID, 60), [2, 60])
    assert_equal(Tower.buildable(Tower::RAPID, 61), [2, 60])
    assert_equal(Tower.buildable(Tower::RAPID, 99), [2, 60])
    assert_equal(Tower.buildable(Tower::RAPID, 100), [3, 100])
    assert_equal(Tower.buildable(Tower::RAPID, 101), [3, 100])
    assert_equal(Tower.buildable(Tower::RAPID, 149), [3, 100])
    assert_equal(Tower.buildable(Tower::RAPID, 150), [4, 150])
    assert_equal(Tower.buildable(Tower::RAPID, 10000), [4, 150])

    assert_equal(Tower.buildable(Tower::RAPID, 19, 0), [0, 0])
    assert_equal(Tower.buildable(Tower::RAPID, 20, 0), [1, 20])
    assert_equal(Tower.buildable(Tower::RAPID, 49, 0), [1, 20])
    assert_equal(Tower.buildable(Tower::RAPID, 50, 0), [2, 50])
    assert_equal(Tower.buildable(Tower::RAPID, 89, 0), [2, 50])
    assert_equal(Tower.buildable(Tower::RAPID, 90, 0), [3, 90])
    assert_equal(Tower.buildable(Tower::RAPID, 139, 0), [3, 90])
    assert_equal(Tower.buildable(Tower::RAPID, 140, 0), [4, 140])

    assert_equal(Tower.buildable(Tower::RAPID, 29, 1), [1, 0])
    assert_equal(Tower.buildable(Tower::RAPID, 30, 1), [2, 30])
    assert_equal(Tower.buildable(Tower::RAPID, 69, 1), [2, 30])
    assert_equal(Tower.buildable(Tower::RAPID, 70, 1), [3, 70])
    assert_equal(Tower.buildable(Tower::RAPID, 119, 1), [3, 70])
    assert_equal(Tower.buildable(Tower::RAPID, 120, 1), [4, 120])

    assert_equal(Tower.buildable(Tower::RAPID, 39, 2), [2, 0])
    assert_equal(Tower.buildable(Tower::RAPID, 40, 2), [3, 40])
    assert_equal(Tower.buildable(Tower::RAPID, 89, 2), [3, 40])
    assert_equal(Tower.buildable(Tower::RAPID, 90, 2), [4, 90])

    assert_equal(Tower.buildable(Tower::RAPID, 49, 3), [3, 0])
    assert_equal(Tower.buildable(Tower::RAPID, 50, 3), [4, 50])
  end
end

class TC_Game < Test::Unit::TestCase
  def test_set_tower
    game = Game.new
    game.set_tower 2,3,0,0
    game.set_tower 2,3,1,0
    assert_equal(game.tower_list.size, 1)
  end

  def test_map
    map = Map.new(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s00001
1000001
1111111
EOF
)
    cost, course_list = map.least_course(1, 3)
    assert_equal(course_list, [[2, 3], [3, 3], [4, 3], [5, 3]])

    cost, course_list = map.least_course(1, 4)
    assert_equal(course_list, [[2, 4], [3, 4], [4, 4], [5, 3]])

    cost, course_list = map.least_course(1, 2)
    assert_equal(course_list, [[2, 2], [3, 2], [4, 2], [5, 3]])

    cost, course_list = map.least_course(1, 2)
    assert_equal(course_list, [[2, 2], [3, 2], [4, 2], [5, 3]])

    cost, course_list = map.least_course(4, 5)
    assert_equal(course_list, [[5, 4], [5, 3]])

    cost, course_list = map.least_course(4, 1)
    assert_equal(course_list, [[4, 2], [5, 3]])

    map = Map.new(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s10001
1000001
1111111
EOF
)
    cost, course_list = map.least_course(1, 4)
    assert_equal(course_list, [[1,3], [2, 3], [3, 3], [4, 3], [5, 3]])
  end



  def test_compute
return
    #putlog_clear
    game = Game.new
    game.new_map(7, 7, <<EOF
1111111
1000001
1s00001
1s000g1
1s00001
1000001
1111111
EOF
)
    game.new_wave 10, 100
    game.set_enemy 1, 4, 12, 44, 40
    game.compute
    assert_equal(game.life, 9)
    assert_equal(game.money, 100)

    game.new_wave 9, 100

    game.set_enemy 1, 4, 12, 44, 40
    game.debug_action(["1 3 0 0"])
    command = game.compute
    assert_equal(game.life, 9)
    assert_equal(game.money, 100)

    game.new_wave 9, 100

    game.set_enemy 1, 4, 12, 44, 40
    game.debug_action(["1 3 4 0"])
    command = game.compute
    assert_equal(game.life, 9)
    assert_equal(game.money, 104)

  end
end

def putlog_clear
#  $putlog_buf = ''
end

def putlog(msg)
#puts msg
#  $putlog_buf += "#{msg}\n"
end

