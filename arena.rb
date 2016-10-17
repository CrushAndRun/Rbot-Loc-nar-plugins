WEAPONSTORE = { 
  :fists =>
    {
      :name => "Fists",
      :description => "This fool has no weapon!",
      :cost => 0,
      :type => "blunt",
      :damage => 2,
      :multiplier => 2
    },
  :broadsword => 
    {
      :name => "Broadsword",
      :description => "A huge sword",
      :cost => 10,
      :type => "slash",
      :damage => 8,
      :multiplier => 1
    }
}

STARTING_GOLD = 100

class ArenaPlugin < Plugin
  def initialize
    super
    @players = Hash.new
  end
  
  def clearstats(m, params)
    @registry.clear
    m.okay
  end
  
  def createplayer(m,params)
    tempstats = rollstats()
    tempplayer = Player.new(Stats.new(tempstats), m.sourcenick, m.sourcenick, STARTING_GOLD)
    
    @players[m.sourcenick] = tempplayer
    
    m.reply "These Are your stats:\nSTR:#{tempstats[0]} DEX:#{tempstats[1]} CON:#{tempstats[2]} INT:#{tempstats[3]} WIS:#{tempstats[4]}"
    m.reply "If you like your stats #arena confirm, otherwise #arena reroll to reroll"
  end
  
  def reroll(m,params)
    tempplayer = @players[m.sourcenick]
    tempstats = rollstats()
    tempplayer.stats = Stats.new(tempstats)
    m.reply "These Are your stats:\nSTR:#{tempstats[0]} DEX:#{tempstats[1]} CON:#{tempstats[2]} INT:#{tempstats[3]} WIS:#{tempstats[4]}"
    m.reply "If you like your stats #arena confirm, otherwise #arena reroll to reroll"
  end
  
  def confirm(m,params)
    tempplayer = @players[m.sourcenick]
    playerhash = Hash.new
    playerhash[:player] = tempplayer
 #   m.reply Marshal.dump(tempplayer)
 #  m.reply(tempplayer.inspect)
 @registry[:playerhash] = playerhash
    m.reply "Your character has been saved"
  end
  
  def rollstats
    tempstats = Array.new
    tempsum = 0
    while tempsum < 60
      tempsum = 0
      tempstats.clear
      for i in 0...5
        tempstats << Dice.roll("3d6")
      end
      tempstats.each { |x| tempsum += x }
    end
    return tempstats
  end
  
  def loadplayer(m,params)
    if !@registry.has_key?("player " + m.sourcenick)
      m.reply "You must create a character first!"
      return
    end
    playerdata = @registry["player " + m.sourcenick]
    @players[:m.sourcenick] = playerdata
    m.reply "Character loaded successfully!"
  end
  def playercheck(m)
    if @registry.has_key?("player " + m.sourcenick)
      return true
    else
      m.reply "You must create a character first!"
      return false
    end
  end
  def shop(m, params)
  end
end

class Player
  def initialize(stats, name, description, gold)
    @stats = stats
    @desciprtion = description
    @arena = false
    @weapon = Weapon.new(:fists)
    @gold = gold
    @temp = true
  end
  attr_accessor :stats
  attr_accessor :weapon
  attr_accessor :gold
  attr_accessor :arena
end

class StatPoint
  def initialize(value)
    @value = value
  end
  def bonus 
    (@value - 10) / 2
  end
  attr_accessor :value
end

class Stats
  def initialize(stats)
    @str = StatPoint.new(stats[0])
    @dex = StatPoint.new(stats[1])
    @con = StatPoint.new(stats[2])
    @int = StatPoint.new(stats[3])
    @wis = StatPoint.new(stats[4])
  end
  attr_reader :str
  attr_reader :dex
  attr_reader :con
  attr_reader :int
  attr_reader :wis
end

class Item
  def initialize(cost, type)
    @cost = cost
    @type = type
  end
  attr_reader :cost
  attr_reader :type
end

class Weapon < Item
  def initialize(weaponid)
    super(WEAPONSTORE[weaponid][:cost], 'weapon')
    @name = WEAPONSTORE[weaponid][:name]
    @description = WEAPONSTORE[weaponid][:description]
    @multiplier =  WEAPONSTORE[weaponid][:multiplier]
    @damage = WEAPONSTORE[weaponid][:damage]
  end
  attr_accessor = :description
  attr_accessor = :name
  attr_reader = :damage
  attr_reader = :multiplier
end

class Dice
  def initialize
  end
  def Dice.roll(d)
    dice = d.split(/d/)
    r = 0
    unless dice[0] =~ /^[0-9]+/
      dice[0] = 1
    end
    for i in 0...dice[0].to_i
      r = r + rand(dice[1].to_i) + 1
    end
    return r
  end
end
plugin = ArenaPlugin.new
plugin.map 'arena enter', :action => 'enter'
plugin.map 'arena'
plugin.map 'arena clearstats', :action => 'clearstats'
plugin.map 'arena load', :action => 'loadplayer'
plugin.map 'arena create', :action => 'createplayer'
plugin.map 'arena reroll', :action => 'reroll'
plugin.map 'arena confirm', :action => 'confirm'
