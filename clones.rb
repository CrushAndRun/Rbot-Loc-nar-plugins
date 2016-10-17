#--
# Copyright 2007 by Stefan Rusterholz.
# All rights reserved.
# See LICENSE.txt for permissions.
#++

trigger "clones"

def on_trigger
	strong = @message.arguments.last != "weak"
	if (@message.arguments.length == 2 && @message.arguments[1].valid_channelname?) then
		all_clones = @butler.channels[message.arguments[1]].clones(strong)
		answer(:clones_in_channel, :channel => message.arguments[1], :count => all_clones.length)
		answer_clones(all_clones)
	else
		all_clones	= @butler.users.clones(strong)
		answer(:all_clones, :count => all_clones.length)
		answer_clones(all_clones)
	end
end

def answer_clones(all_clones)
	all_clones.each { |common, clones|
		answer(:clonelist, :common => common, :clones => clones)
	}
end

__END__
--- 
:revision:
  :plugin: 1
:summary:
  en: Let butler send a notice to a user or channel
:about:
  :mail: "apeiros@gmx.net"
  :version: "1.0.0"
  :author: "Stefan Rusterholz"
:strings:
  :clones_in_channel:
    en: |
      Clones in channel <%= channel %> (<%= count %>):
  :all_clones:
    en: |
      All clones (<%= count %>):
  :clonelist:
    en: |
      <%= common %>: <%= clones.map { |u| "#{u.nick}" }.join(", ") %>
:usage:
  en: |
    ![b]notice![o] (![c(green)]nick![o] | ![c(green)]channel![o])
:help:
  en:
    "": |
      Let butler send a notice to a user or channel.
