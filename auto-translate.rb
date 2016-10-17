require 'json'
require 'net/http'

class AutoTranslatePlugin < Plugin

  ## TRANSLATIONS contains hashes that describe every translation to be made :
  ## - src : source channel
  ## - dst : destination channel
  ## - src_lang : source language
  ## - dst_lang : translation language
  

  TRANSLATIONS = [ {"src" => "#myfirstchannel", "dst" => "#myfirstchannelFr", "src_lang" => "en", "dst_lang" => "fr"},
    		   {"src" => "#mysecondchannel", "dst" => "#mysecondchannelNo", "src_lang" => "en", "dst_lang" => "no"} ]

  ## IGNORE_NICKS contains a list of nicks whose messages must not be translated

  IGNORE_NICKS = [ "somebot", "anotherbot" ]

  SRC_CHANNELS =  (TRANSLATIONS.collect {|t| t["src"]}).uniq!

  def help(plugin, topic="")
    "Automatic channel translation plugin. See source code for details..."
  end

  def message(m)
    return if m.address?
    return if IGNORE_NICKS.include?(m.source.nick)
    return if !(SRC_CHANNELS.include?(m.channel.to_s))		
    Thread.new { traduc(m) }
  end

  def traduc(m)

   base_url = "http://ajax.googleapis.com/ajax/services/language/translate"
   channel = m.channel.to_s

   TRANSLATIONS.each do |trans|
	next if trans["src"] != channel
   	url = "#{base_url}?v=1.0&q=#{URI.encode(m.message)}&langpair=#{URI.encode(trans['src_lang'])}%7C#{URI.encode(trans['dst_lang'])}"
   	resp = Net::HTTP.get_response(URI.parse(url))
	data = resp.body
         
   	result = JSON.parse(data)
   	next if result["responseStatus"] != 200
   	answer = result["responseData"]["translatedText"]                  

   	if(answer.length > 600)
      		@bot.say trans['dst'], "[Erreur] Réponse trop longue"
      		next
   	end
   	answer = answer.downcase
   	answer = Utils.decode_html_entities(answer)
   	@bot.say trans['dst'],  "[#{trans['src']}] <#{m.source.nick}> #{answer}"
   end

  end

end

plugin = AutoTranslatePlugin.new