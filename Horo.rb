require 'rss'

class HoroPlugin < Plugin

  FEEDURL = 'http://feeds.astrology.com/'
  HOROS = %w{dailyoverview dailysingleslove dailycoupleslove dailywork
             dailyextended
             weeklyoverview weeklyromantic weeklytravel weeklybusiness
             monthlyoverview monthlyromantic monthlycareer monthlyfitness
             }
  SIGNS = %w{aries taurus gemini cancer leo virgo libra scorpio saggitarius
             capricorn aquarius pisces}

  def initialize
    super
    class << @registry
      def store(val)
        val
      end
      def restore(val)
        val
      end
    end
  end

  def help(plugin, topic="")
    "horo [<sign>] [<type>] => astrology.com current horoscope for <sign>; horo set <sign> => set default sign for the user.\n" +
      "Signs are: #{SIGNS.join(' ')}, Types are: #{HOROS.join(' ')}"
  end

  def horo_set(m, params)
    begin
      s = params[:sign] or raise "set to what?"
      sign = SIGNS.find { |si| si =~ /#{s}/i } or raise "unknown sign #{s}"
      @registry[m.sourcenick] = sign
      m.okay
    rescue Exception => e
      m.reply "error: #{e.message}"
    end
  end

  def horo(m, params)
    debug params.inspect
    Thread.new do
      begin
        h = params[:type]
        sign_s = params[:sign]
        if !sign_s || sign_s.empty?
          sign_s = @registry[m.sourcenick]
        end
        raise "i don't know your sign" if sign_s.nil? || sign_s.empty?

        horo = HOROS.find { |ho| ho =~ /#{h}/i } or raise 'unknown horo'
        sign = SIGNS.find { |si| si =~ /#{sign_s}/i } or raise 'unknown sign'
        rss = RSS::Parser.parse(@bot.httputil.get(FEEDURL + horo), nil)
        item = rss.items.to_a.find { |i| i.title =~ /^#{sign}/i }

        m.reply item.title
        m.reply item.description.sub(/\<\/p\>.*/m, '').gsub(/\<[^\>]+\>/, '')
      rescue Exception => e
        m.reply "error (sorry, snaky!) -> #{e.message}"
        debug e.backtrace.join("\n")
      end
    end
  end
end
plugin = HoroPlugin.new
plugin.map 'horo set :sign', :action => 'horo_set'
plugin.map 'horo [:type] [:sign]', :defaults => {:type => '', :sign => nil}
plugin.map 'horo'