# Copyright (c) 2006-2007 Harald Sitter <harald.sitter@kdemail.net>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies of the Software and its documentation and acknowledgment shall be
# given in the documentation and software packages that this Software was
# used.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# NOTE: for description of beats see 'calc beats' in #amaork

# Class for storing good values
# # # Stock = Struct.new( "Stock", :amount, :max, :beats, :deliverybeat, :version )
Stock = Struct.new( "Stock", :version, :amount, :max, :beats, :deliverybeat, :machine )

# Class for storing custom replies
Reply = Struct.new( "Reply", :version, :reply )

class BARPlugin < Plugin

  ####
  # Initialize Database
  ####
  def initialize()
  super
    if @registry.has_key?(:stock)
      @stock = @registry[:stock]
    else
      @stock = Hash.new
    end

    if @registry.has_key?(:reply)
      @reply = @registry[:reply]
     else
      @reply = Hash.new
    end

    @stockversion = "2"
    @replyversion = "1"
  end

  ####
  # Save Database
  ####
  def save
    @registry[:stock] = @stock
    @registry[:reply] = @reply
  end

  ####
  # Majorcheck
  ####
  def majorcheck( m, name, nick )
    # if the order is in our db, check whether we still have some of it - if yes: reduze amount by one
    if @stock[name].amount.to_f <= 0
      @available = false
      # if we don't have the order anymore - check whether the deliverybeat equals nil, if this is case tell the user to reorder
      if @machine == false
        @machine = true
      end
      if @stock[name].deliverybeat != nil
        # check whether the reordered good is available - if not, tell the user it's in progress and how long to go
        delivery( m, name )
        if @available != true
          if @machine
            order = "tells #{nick} that our #{name} is broken, but fortunately a technician is already working on it (#{@togo.to_s} minutes)."
          else
            order = "tells #{nick} that we are out of #{name} but a new delivery is already in progress (#{@togo.to_s} minutes)."
          end
          @bot.action m.replyto, order; return
        end
        # tell _the ordering user_ to reorder because we are out of the ordered good
      else
        if @machine
          m.reply( "#{m.sourcenick}: Our #{name} machine seems to be broken, maybe you should get someone to repair it."); return
        else
          m.reply( "#{m.sourcenick}: We are out of #{name}, you should reorder some of it."); return
        end
      end
    end
    # decrease amount of ordered good by one
    @stock[name].amount = @stock[name].amount.to_i - 1
    @available = true
  end

  ####
  # Get Delivery status
  ####
  def delivery( m, name )
    beat_cur     = Time.new.strftime '%Y%j%H%M%S'
    deliverybeat = @stock[name].deliverybeat

    if beat_cur.to_f >= deliverybeat.to_f
      @stock[name].amount       = @stock[name].max
      @stock[name].deliverybeat = nil
      @registry[:stock]         = @stock
      @available                 = true
      # if it's not available, set value according
    else
      @togo = (deliverybeat.to_f - beat_cur.to_f) / 100
      @available = false
    end

    #     TODO: compare current beat with order beat and decide whether to increase
    #           the amount to amount of order or not. If not, tell the user how long
    #           to wait.
  end

  ####
  # Check whether good is in database
  ####
  def status( name, reg )
    @inreg = true

    unless reg.has_key?( name )
      @inreg = false
    end
  end

################################################################################

  ####
  # Add new Good to Database
  ####
  def handle_add( m, params )
    # lame auth check
    # TODO: need to get a look into new auth system

    name         = params[:name].downcase
    machine      = params[:machine].downcase
    amount       = params[:amount]
    beats        = params[:beats]

      # caluclate beats for one good and multiply with 100 -> better for later use
      beats = beats.to_f / amount.to_f
      beats *= 100

      # tag version || current amount || maximal amount || beats for one good || deliverybeat (always 'nil' if not reordered) || linked machine
    if machine == "-"
      stock = Stock.new( @stockversion, amount, amount, beats, nil, machine )
      @stock[name] = stock

      m.reply( "#{name} added" )
    elsif machine == "yes"
      name += "_machine"
      stock = Stock.new( @stockversion, amount, amount, beats, nil, machine )
      @stock[name] = stock

      m.reply( "#{name} added" )
    elsif machine == "no" and @stock.has_key?( name + "_machine" )
      machine = name + "_machine"
      stock = Stock.new( @stockversion, amount, amount, beats, nil, machine )
      @stock[name] = stock

      m.reply( "#{name} added" )
    else
      m.reply( "Please first create the machine which should be linked to (same syntax, just replace the machine name with 'yes'), or use '-' to inidcate that there is no machine." ); return
    end

    # save dataset in case the bot crashes an got no chance to do so
    save
  end

  ####
  # Add reply for defined Good
  ####
  def handle_add_reply( m, params )
    # lame auth check
    # TODO: need to get a look into new auth system

    name    = params[:name].downcase
    reply   = params[:reply].to_s

    # check whether good is in database
#     status( name, @stock )
#     if @inreg == false
#       m.reply( "#{name} does not exist." ); return
#     end

    # Put data into database, should be understandable ^^
    reply = Reply.new( @replyversion, reply )
    @reply[name] = reply

    # save dataset in case the bot crashes an got no chance to do so
    save

    m.reply( "done" )
  end

  ####
  # Delete Good from Database
  ####
  def handle_del( m, params )
    name = params[:name].downcase.sub(/[ ]/, '_')
    unless @stock.has_key?( name )
      m.reply( "Not in registry." ); return
    end
    @stock.delete(name)
    @registry[:stock] = @stock
    m.reply( "done" )
  end

  ####
  # List all items in Database
  ####
  def handle_list( m, params )
    if @stock.length == 0
      m.reply( "Nothing available." ); return
    end

    m.reply "Finite goods: #{@stock.keys.sort.join(', ')}"
  end

  ####
  # List all custom replies in Database
  ####
  def handle_list_reply( m, params )
    if @reply.length == 0
      m.reply( "Nothing available." ); return
    end

    m.reply "Custom replies: #{@reply.keys.sort.join(', ')}"
  end

  ####
  # Show information about Good (amount, max, beats, deliverybeat, tag version)
  ####
  def handle_show( m, params )
    name = params[:name].downcase

    unless @stock.has_key?( name )
      m.reply( "#{name} does not exist." ); return
    end

    cmd = @stock[name]
    m.reply( "#{if cmd.machine == "-"; "No linked machine |||"; else; "Linked machine: " + cmd.machine + " |||"; end } Amount: #{cmd.amount} ||| Max: #{cmd.max} ||| 1 good per #{cmd.beats} beats |||#{if cmd.deliverybeat != nil; cmd.deliverybeat.to_s + " |||"; end } Tag version: #{cmd.version}" )
  end

  ####
  # Show custom reply
  ####
  def handle_show_reply( m, params )
    name = params[:name].downcase

    status( name, @reply )
    if @inreg == false
      m.reply( "#{name} does not exist." ); return
    end

    cmd = @reply[name]
    m.reply( "Reply: \"#{cmd.reply}\" ||| Tag version: #{cmd.version}" )
  end

  ####
  # Process reording of Good (calculate deliverybeat and set it)
  ####
  def handle_reorder( m, params )
    name         = params[:name].downcase
    beat_cur     = Time.new.strftime '%Y%j%H%M%S'

     status( name, @stock )
     if @inreg == false
       m.reply( "#{name} does not exist." ); return
     end

    # check status of delivery if beat != nil (aka someone reordered) - either tell it is avail. again or tell how long to wait
    if @stock[name].deliverybeat != nil
      delivery( m, name )
      if @available == true
        m.reply( "#{m.sourcenick}: #{name} is again available now." ); return
      else
        if @stock[name].machine == "yes"
          m.reply( "#{m.sourcenick}: technican is already working (#{@togo.to_s} minutes)." ); return
        else
          m.reply( "#{m.sourcenick}: #{name} has already been ordered (#{@togo.to_s} minutes)." ); return
        end
      end
    end

    if @stock[name].amount.to_f >= ((@stock[name].max.to_f * 25) / 100)
      if @stock[name].machine == "yes"
        m.reply( " #{m.sourcenick}: #{name} machine is working like a charm." ); return
      else
        m.reply( " #{m.sourcenick}: We still have enough #{name}, no need to reorder." ); return
      end
    end

    # run calculation after checks to save resources if not needed
    deliverybeat = beat_cur.to_i + (@stock[name].beats.to_i * @stock[name].max.to_i)

    @stock[name].deliverybeat = deliverybeat
    @registry[:stock] = @stock

    if @stock[name].machine == "yes"
      m.reply( "A technican is on the way....")
    else
      m.reply( "The beer bitch is on his way to the store....")
    end

    #     NOTE: needs new registry hashes for beat per amount and for beat at time
    #           of order
    #     TODO: implement amount option
  end

  ####
  # Reset reording of Good (set deliverybeat to nil)
  ####
  def handle_reorder_reset( m, params )
    name = params[:name].downcase

    unless @stock.has_key?( name )
      m.reply( "#{name} does not exist." ); return
    end

    @stock[name].deliverybeat = nil
    @registry[:stock]         = @stock

    m.reply( "done" )
  end

  ####
  # Main Process, takes care of usual order cmd (check availability, delivery status, special order etc.)
  ####
  def process( m, params )
    order      = nil
    @available = false
    @togo      = nil

    scantmp = m.params.scan(/.*for.*/)
    if scantmp.length == 0
      name = m.params
      nick = m.sourcenick
    else
      for_idx = m.params =~ /\s+\bfor\b/
      name = m.params[0, for_idx]

      for_idx = m.params.reverse =~ /\s+\brof\b/
      nick = m.params.reverse[0, for_idx]
      nick = nick.reverse
    end
    name = name.downcase
    # check whether the order is in our database
    if @stock.has_key?( name )
      @machine = nil
      majorcheck( m, name, nick )
      if @available != true
        return
      end
      if @stock[name].machine == "yes"
        m.reply( "You can't ORDER machines. (try repair)" ); return
      elsif @stock[name].machine != "-"
        @machine = false
        majorcheck( m, @stock[name].machine, nick )
        if @available != true
          return
        end
      end
    end

    # !!!! special feature if someone stands something for everyone !!!!
    if nick == "everyone"
      order = "is going to his secret storehouse to get #{name} for #{nick} - might be expensive."
      @bot.action m.replyto, order
      # !!!! result: amount is going down to 0 no matter which value it was before
      @stock[name].amount = "0"
      return
    end

    order = case name
      # list of replies we can't move to registry yet, because multi-word-calls don't work properly
      # TODO: fix that god damn multi-word bug
    when "list" then
      "currently lists [bed/beer/steele reserve/birthday package/hangover/breakfast/brain/can of whoopass/chocolate/skittles/coffee/espresso/cafe con leche/cushion/solution/heineken/fosters/good beer/mimosa/hot tea/iced tea/whore/goodys/wine/dildo/bacon/winning lottery ticket/sex on the beach/cheese/pussy/intelligence/jelly beans/help/sex/jokes/idiocy/sammich/pb&j] to choose from otherwise use [order <item>] or [order <item> for <nick>]."
    when "bed" then
      "is placing a cot for #{nick} in the corner of #{m.target}."
    when "beer" then
      "gives #{nick} a nice frosty mug of #{name}."
    when "steele reserve" then
      "gives #{nick} a nice frosty mug of #{name}."	  
    when "birthday package" then
      "is running to the corner shop to get a birthday present."
    when "hangover" then
      "slides 2 liter of water, one glass of tomato juice, 3 rollmops and chips down the bar to #{nick}"
    when "breakfast" then
      "prepares a bowl of cereal with milk, 2 pancakes, scrambled eggs with bacon, a cup of hot coffee and a glass of orange juice for #{nick}."
    when "brain" then
      "shouts: OMG!!!!! RED ALERT! We lost a #{name}. Get me a medic, NOW!"
    when "can of whoopass" then
      "opens up a can of whoopass on #{nick}. Chuck Norris jumps out."
    when "chocolate" then
      "hands #{nick} a Toblerone bar."
    when "skittles" then
      "gives #{nick} a large bag of skittles."	  
    when "coffee" then
      "slides a fresh cup of hot #{name} down the bar to #{nick}."
    when "espresso" then
      "serves #{nick} a hot shot of cuban #{name}."
    when "cafe con leche" then
      "serves #{nick} a warm cup of cafe con leche."	  
    when "cushion" then
      "is getting #{nick} a cushion from his private footlocker."
    when "solution" then
      "gets #{nick} a hammer and a gun, now you must choose."	  
    when "heineken" then
      "gives #{nick} a nice frosty wonderful green bottle of #{name}."
    when "fosters" then
      "gives #{nick} a frosty cold glass of #{name}."	  
    when "good beer" then
      "slides the finest Belgium Trappist beer down the bar to #{nick}."
    when "mimosa" then
      "mixes up a chilled glass of orange juice and champagne for #{nick}."	  
    when "hot tea" then
      "heats up a cup of earl grey for #{nick}."
    when "iced tea" then
      "pours #{nick} an ice cold glass of southern tea."	  
    when "whore" then
      "slides apachelogger down the bar to #{nick}."
    when "goodys" then
      "passes #{nick} a goody powder and a cold glass of water."	  
    when "wine" then
      "pours #{nick} a delicious glass from the channel's wine cellar."
    when "dildo and a sweater" then
      "passes #{nick} a warm sweater, if you don't like that then here's a dildo..go fuck yourself."
    when "bacon" then
      "yells what?! all your bacons are belong to me! order something else #{nick}."
    when "winning lottery ticket" then
      "gasps...really? like i'd deliver on that order #{nick} pfft."
    when "sex on the beach" then
      "turns on the camera and brings a lot lizard to the beach for #{nick}."
    when "cheese" then
      "farts in #{nick} general direction."	  
    when "pussy" then
      "thinks you should go fuck yourself, you'll get more pussy that way #{nick}."
    when "intelligence" then
      "places a dunce cap on #{nick} all better now."
    when "jelly beans" then
      "slides #{nick} a bowl of JellyBellys." 
    when "help" then
      "suggests that #{nick} just enter /quit I'm helpless."
    when "sex" then
      "tosses #{nick} a tube of hand lotion and recommends shuurl.com."
    when "jokes" then
      "tosses a paperback copy of This Is Your Life to #{nick}."
    when "idiocy" then
      "recommends that #{nick} connect to irc.freenode.net and /join #defocus."
    when "sammich" then
      "prepares a Monte Cristo for #{nick} served with a cold beer."
    when "pb&j" then
      "makes a peanut butter and jelly sammich for #{nick}."
    when "rickroll" then
      "recommends http://is.gd/just_click_me for #{nick}."
    when "religion" then
      "found this link http://x0.no/coey for #{nick} click it!"
    else
      "magically produces #{name} just for #{nick}"
    end

#     status( name, @reply )
#     if @inreg != false
#       order = @reply[name].reply
# #       m.reply( order.class.to_s )
# #       m.reply( "registry -> reply" )
# 
#       order.gsub!( "<name>", name )
#       order.gsub!( "<nick>", nick )
#       order.gsub!( "<target>", m.target.to_s )
#     end

    @bot.action m.replyto, order
    if name == "birthday package"
      @bot.action m.replyto, "presents #{nick} with a birthday cake and a present then serves everyone a boilermaker."
      m.reply( "Happy birthday to you, happy birthday to you, happy birthday #{nick}, happy birthday to you!!!!" )
      m.reply( "\002Happy Birthday #{nick} :D" )
      m.reply( "Bottoms Up!" )
	  m.reply( "burp!" )
    end

  end
end

plugin = BARPlugin.new
plugin.register("order")

# TODO: point out how to make it work with 2 or more word names
plugin.map 'order *wish',                        :action => 'process'
plugin.map 'order-adm add :name :machine :amount :beats', :action => 'handle_add',
                                                          :auth_path => 'add',
                                                          :requirements => {:amount => /^\d+$/, :beats => /^\d+$/}
# plugin.map 'order-adm add-reply :name *reply',   :action => 'handle_add_reply'
# plugin.map 'order-adm del :name',                :action => 'handle_del'
plugin.map 'order-adm list',                     :action => 'handle_list'
plugin.map 'order-adm list-reply',               :action => 'handle_list_reply'
plugin.map 'order-adm show :name',               :action => 'handle_show'
plugin.map 'order-adm show-reply :name',         :action => 'handle_show_reply'
plugin.map 'reorder :name',                      :action => 'handle_reorder'
plugin.map 'reorder reset :name',                :action => 'handle_reorder_reset'
plugin.map 'repair :name',                       :action => 'handle_reorder'
