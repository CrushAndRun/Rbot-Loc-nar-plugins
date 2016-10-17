#-- vim:sw=2:et
#++
#
# :title: Qdb quote fetcher 
#
# Author:: Jan Wikholm <jw@jw.fi>
# Copyright:: (C) 2008 Jan Wikholm
# License:: MIT
#

require 'rubygems'
require 'hpricot'

class QdbPlugin < Plugin

  def help(plugin, topic="")
      "qdb <id> => fetch qdb quote by id"
  end

  def retrieve(m)
    request = m.params
    url = "http://www.qdb.us/#{request}"
    begin
      doc = Hpricot(@bot.httputil.get(url))
      quote = (doc/"table[@class='quote']/tr[2]/td[1]/p").text.split("\n")
      if quote.size <= @bot.config['send.max_lines']
        quote.each {|line| m.reply line }
      else
        m.reply "quote too long (%s lines), see for yerself: %s or change limit by: config set send.max_lines NUMBER" % [quote.size, url]
      end

    rescue => e
      m.reply "Fail"
    end
  end

  def privmsg(m)
    retrieve(m)
  end
end

plugin = QdbPlugin.new
plugin.map "qdb *request", :action => 'retrieve', :thread => "yes" #so it won't lock