#++
#
# :title: Meme generator plugin for rbot.
#
# Author:: Matthew M. Boedicker <matthewm@boedicker.org>
#
# Copyright:: (c) 2011 Matthew M. Boedicker
#
# License:: MIT
#
# Version:: 0.4
#
# Generates a meme image from memegenerator.net.

require 'open-uri'
require 'shellwords'

require 'imgur2'
require 'meme'

class MemeGeneratorPlugin < Plugin

  def help(plugin, topic='')
    case topic
      when 'list' then
        'meme list => list meme generators'
      when 'imgur' then
        'meme imgur key => set imgur API key'
      else
        'generate a meme image using memegenerator.net: meme (imgur [key] | list | generator line1 [additional lines])'
    end
  end

  def list(m, params)
    m.reply(Meme::GENERATORS.map { |k,v| "#{k}=#{v[2]}" }.sort.join(', '))
  end

  def gen(m, params)
    begin
      lines = Shellwords.split(params[:lines].join(' '))
      if lines.size > 0
        generator = Meme.new(params[:generator])
        img_url = generator.generate(*lines)
        if @registry[:imgur_key]
          imgur_client = Imgur2.new(@registry[:imgur_key])
          open(img_url, 'rb') do |f|
            m.reply imgur_client.upload(f)['upload']['links']['original']
          end
        else
          m.reply img_url
        end
      else
        m.reply "incorrect usage: #{help m.plugin}"
      end
    rescue Meme::Error => e
      m.reply e
    end
  end

  def imgur_key(m, params)
    @registry[:imgur_key] = params[:key]
    m.reply 'imgur key set'
  end

end

plugin = MemeGeneratorPlugin.new
plugin.map 'meme list', :action => 'list'
plugin.map 'meme imgur :key', :action => 'imgur_key'
plugin.map 'meme :generator *lines', :action => 'gen'
