class DiskInfoPlugin < Plugin
  def help(topic)
    return "dinfo: return total, used and free system space."
  end
  
  def dinfo(m, params)
    df_total = `df --total | tail -n1`
    if df_total.match /total\s+(\d+)\s+(\d+)\s+(\d+)/
     used = $2.to_i / 1024.0 / 1024.0
     free = $3.to_i / 1024.0 / 1024.0
     total = used + free
     m.reply("Size: #{total.round} GiB | Used: #{used.round} GiB | Free: #{free.round} GiB")
    end
  end
end
plugin = DiskInfoPlugin.new
plugin.map 'dinfo'