require 'json'
require 'net/http'

class AutoTranslatePlugin < Plugin

  ## TRANSLATIONS contains hashes that describe every translation to be made :
  ## - src : source channel
  ## - dst : destination channel
  ## - src_lang : source language
  ## - dst_lang : translation language
  

  TRANSLATIONS = [ {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "zh-CN", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "zh-TW", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "da", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "nl", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "tl", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "fi", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "fr", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "el", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ga", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "it", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ja", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ko", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "la", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ms", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "no", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "pl", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "pt", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ro", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "ru", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "es", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "sv", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "th", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "tr", "dst_lang" => "en"},
	           {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "uk", "dst_lang" => "en"},
    		   {"src" => "#cornerpocket", "dst" => "#cornerpocketEn", "src_lang" => "vi", "dst_lang" => "en"} ]

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
      		@bot.say trans['dst'], "[Error] Response too long."
      		next
   	end
   	answer = answer.downcase
   	answer = Utils.decode_html_entities(answer)
   	@bot.say trans['dst'],  "[#{trans['src']}] <#{m.source.nick}> #{answer}"
   end

  end

end

plugin = AutoTranslatePlugin.new
