#-- vim:sw=2:et
#++
#
# :title: Check Page
#
# Author:: Five <five on irc.freenode.net>
# License:: Public Domain
#
# Checks a URL regularly to see if it has been updated


class CheckPagePlugin < Plugin

  Config.register Config::StringValue.new('checkpage.url',
    :default => "http://www.example.com", 
    :desc => 'URL of the page you want to check')
  Config.register Config::StringValue.new('checkpage.channel',
    :default => '#yourchannel',
    :desc => 'name of the channel to announce on')
  Config.register Config::IntegerValue.new('checkpage.seconds',
    :default => 900,
    :desc => 'number of seconds to check (15 minutes is default)')
  Config.register Config::IntegerValue.new('checkpage.message',
    :default => "Page updated!",
    :desc => 'message displayed before the URL when the announcement is made')

  def help(plugin, topic="")
    return "Checks #{@bot.config['checkpage.url']} every #{@bot.config['checkpage.seconds']} seconds and tells everyone on #{@bot.config['checkpage.channel']} when its updated."
  end

  def initialize
    super
    @last_update = @bot.httputil.get(@bot.config['checkpage.url'])
    @timer = @bot.timer.add(@bot.config['checkpage.seconds']) { check_page }
  end
  
  def cleanup
    @bot.timer.remove(@timer)
  end

  def check_page
    html = @bot.httputil.get(@bot.config['checkpage.url'])
    if html != @last_update
      @bot.say @bot.config['checkpage.channel'], "#{@bot.config['checkpage.message']} #{@bot.config['checkpage.url']}"
      @last_update = html
    end
  end

end

plugin = CheckPagePlugin.new