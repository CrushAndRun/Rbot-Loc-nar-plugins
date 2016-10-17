require 'date'
require 'astro/moon'

class MoonPlugin < Plugin
  def help(plugin, topic="")
    "moon => shows the phase of the moon; moon on => announce full/new moon; moon off => don't announce full/new moon"
  end

  def initialize(*a)
    super
    @timers = Array.new
    self.init_timers
  end

  def init_timers
    now = DateTime.now
    ph = Astro::Moon.phasehunt
    add_timers(ph.moon_start, 'New', now)
    add_timers(ph.moon_full, 'Full', now)
    add_timers(ph.moon_end, 'New', now)
  end

  def add_timers(date, msg, now)
    [
      [-12 * 3600, "Be advised, #{msg} Moon tonight!"],
      [-15 * 60, "Be advised, #{msg} Moon in 15 minutes!"],
      [0, "The Moon is #{msg} *NOW*!"],
      [12 * 3600, "#{msg} Moon is over (12 hours ago)"]
    ].each do |_|
      delta = ((date - now) * 86400).to_i + _[0]
      next if delta <= 0
      @timers.push @bot.timer.add_once(delta) {
        self.announce(_[1])
        @timers.shift or self.init_timers
        }
      end
   end
end