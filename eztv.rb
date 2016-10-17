require 'time'
require 'rexml/document'
require 'uri/common'

class EztvPlugin < Plugin

  include REXML

  def help(plugin, topic="")
    "eztv [<max>=8] => show eztv torrents, [<max>=8] => return up to <max> headlines " +
    "(use a negative number to show all the torrents in one line)"
  end

  def eztv(m, params)
    max = params[:limit].to_i
    debug "max is #{max}"
    xml = @bot.httputil.get('http://tvrss.net/feed/eztv/')
    unless xml
      m.reply "eztv parse failed"
      return
    end
    doc = Document.new xml
    unless doc
      m.reply "eztv parse failed (invalid xml)"
      return
    end

    done = 0
    oneline = false
    if max < 0
      max = (0 - max)
      oneline = true
    end
    max = 5 if max > 5
    matches = Array.new
    doc.elements.each("rss/channel/item") {|e|
      matches << [ e.elements["title"].text, 
                   Time.parse(e.elements["pubDate"].text).strftime('%a @ %I:%M%p'),
                   e.elements["link"].text ]
      done += 1
      break if done >= max
    } 

    if oneline
      m.reply matches.collect{|mat| mat[0]}.join(" | ")
    else
      matches.each {|mat|
        m.reply sprintf("%42s | %13s | %s", mat[0][0,42], mat[1], mat[2])
      }
    end
  end
end

plugin = EztvPlugin.new
plugin.map 'eztv :limit', :defaults => {:limit => 5},
                          :requirements => {:limit => /^-?\d+$/}