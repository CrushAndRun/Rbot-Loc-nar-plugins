#-- vim:sw=2:et
#++
#
# :title: Coolguy's HotGirlOfTheDay plugin for RBot
# :author: Jason Hines, <jason@greenhell.com>
# :version: 0.1
#

class HotGirlOfTheDayPlugin < Plugin
  REG  = Regexp.new('&lt;img src="([a-zA-Z:\/\/\._0-9]+)"')

  def initialize
    super
    @texts = Array.new
  end

  def help( plugin, topic="" )
    return _("Usage: botnick: hottie.")
  end

  def hgotd(m, params)
    opts = { :cache => false }
    begin
        if @texts.empty?
          data = @bot.httputil.get("http://feeds.feedburner.com/hgotd/", opts)
          res = data.scan(REG)
          res.each do |quote|
            @texts << CGI.unescapeHTML(quote[0])
          end
        end
        
        text = @texts.sort { rand(@texts.size) - 1 }.pop
        m.reply shorten_url(text)
    rescue
      m.reply "failed to connect to the hottie source"
    end
  end

  def shorten_url(url)
    res = Net::HTTP.post_form(URI.parse('http://borurl.com/api/'), {'action'=>'shorturl','format'=>'simple','url'=>url})
    res.body.empty? ? url : res.body
  end

end


plugin = HotGirlOfTheDayPlugin.new

plugin.default_auth('create', false)

plugin.map "hottie [:num]", :thread => true, :action => :hgotd, :requirements => { :num => /\d+/ }
