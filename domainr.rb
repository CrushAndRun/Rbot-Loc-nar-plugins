#-- vim:sw=2:et
#++
#
# :title: domai.nr plugin for RBot
# :author: Jason Hines, <jason@greenhell.com>
# :version: 0.1
#

#require 'rubygems'
require 'rest_client'
require 'json'

class DomainrPlugin < Plugin

  def help( plugin, topic="" )
    return _("Usage: 'domainr term' to find domain name variations using domai.nr")
  end

  def domainr(m, params)
    response = RestClient.get('http://domai.nr/api/json/search?q=' + params[:term])
    if response.code == 200
      result = JSON.parse(response.body)
      result['results'].each do |d|
        m.reply "#{d['domain']}#{d['path']} (#{d['availability']})" unless d['availability']=='tld'
      end
    else
      m.reply "Error"
    end
  end
end

plugin = DomainrPlugin.new
plugin.map "domainr :term"