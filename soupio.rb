#-- vim:sw=2:et
#++
#
# :title: Soup.io Plugin for rbot
#
# Author:: Matthias Hecker <apoc@sixserv.org>
#
# Copyright:: (C) 2009 Matthias Hecker
#
# License:: GPL v2
#
# Soup.io Plugin for publishing Links, Images, Texts, Quotes and Videos.
# This Plugin requires WWW::Mechanize in a version >= 0.9.0
# Please mail me Bugs, Feedback, Feature-Requests. (apoc@sixserv.org)
# You could find me also at the #rbot Channel in Freenode. 
#
# TODOs:
# * Move SoupIoClass to registry (?)
# * Change Mechanize to Net::HTML (ruby stdlib ??)

require 'rubygems'
require 'mechanize' # >= 0.9.0 is required !!!
require 'cgi'

class SoupIoClass
  # Username
  attr_reader :user
  
  # Password
  attr_reader :pass
  
  # User Domain
  attr_reader :domain
  
  # Session ID
  attr_reader :sessid
  
  def initialize(user, pass, domain = nil, sessid = nil)
    @user = user
    @pass = pass
    @domain = domain
    @sessid = sessid
    
    @agent = WWW::Mechanize.new
    
    # Login when domain is empty
    login if domain == nil
  end
  
  def login
    # build login form and submit
    post = {
    'login' => @user,
    'password' => @pass,
    'commit' => 'Log in'
    }
    page = @agent.post('https://www.soup.io/login', post)

    # parse user domain from mainpage
    if page.body.match(/<li><a href="http:\/\/([^"]+)">.*<span>My Soup<\/span><\/a><\/li>/) then
      tmp_domain = $1.gsub(/\/$/, '')
      # User customized domain?
      if tmp_domain == "www.soup.io/go/#{@user}" then
        page = @agent.get "http://#{tmp_domain}"
        if page.body.match(/src="http:\/\/([^\/]+)\/ping"/) then
          @domain = $1
        end
      else # normal soup domain...
        @domain = tmp_domain
      end
    else
      # Error, wrong login(?)
      return false
    end

    page = @agent.get "http://#{@domain}/ping"
    @agent.get "http://soup.io/remote/generate?host=#{@domain}&redirect_to=%2F&referer=http%3A%2F%2Fwww.soup.io%2Fgo%2F#{@user}"
    
    # Get the SessionID
    @agent.cookies.each do |cookie|
      @sessid = cookie.value if cookie.name == 'soup_session_id' and cookie.domain == @domain
    end
  end
  
  # the default save request
  def get_default_request
    {
      'post[source]' => '',
      'post[body]' => '',
      'post[body]WidgEditor' => 'true',
      'post[id]' => '',
      'post[parent_id]' => '',
      'post[original_id]' => '',
      'post[edited_after_repost]' => '',
      'redirect' => '',
      'commit' => 'Save'
    }
  end
  
  def post_submit(request)
    backup_cookie = ''
    request.each_pair do |key,value|
      backup_cookie += "#{key}=#{value}&"
    end
  
    @agent.pre_connect_hooks << lambda do |params|
      params[:request]['Cookie'] = "soup_session_id=#{@sessid}"
    end
  
    @agent.post("http://#{@domain}/save", request)
  end
  
  def new_link(url, title = '', description = '')
    request = get_default_request()
    request['post[type]'] = 'PostLink'
    request['post[source]'] = url
    request['post[title]'] = title
    request['post[body]'] = description
    
    post_submit(request)
  end
  
  def new_image(url, description = '')
    request = get_default_request()
    request['post[type]'] = 'PostImage'
    request['post[url]'] = url
    request['post[source]'] = url
    request['post[body]'] = description
    
    post_submit(request)
  end
  
  def new_text(text, title = '')
    request = get_default_request()
    request['post[type]'] = 'PostRegular'
    request['post[title]'] = title
    request['post[body]'] = text
    
    post_submit(request)
  end
  
  def new_quote(quote, source)
    request = get_default_request()
    request['post[type]'] = 'PostQuote'
    request['post[body]'] = quote
    request['post[title]'] = source
    
    post_submit(request)
  end
  
  def new_video(youtube_url, description = '')
    request = get_default_request()
    request['post[type]'] = 'PostVideo'
    request['post[embedcode_or_url]'] = youtube_url
    request['post[body]'] = description
    
    post_submit(request)
  end
end

# API:
#
#soup = SoupIoClass.new('[Username]', '[Password]'<, '[Domain]', '[Session-ID]'>)
#soup.new_link '[URL]'<, '[Title]', '[Description]'>
#soup.new_image '[URL]'<, '[Description]'>
#soup.new_text '[Text]'<, '[Title]'>
#soup.new_quote '[Quote]'<, '[Source]'>
#soup.new_video '[Youtube-URL]'<, '[Description]'>
#

# Testing:
#
#soup = SoupIoClass.new('USERNAME', 'PASSWORD')
#soup.new_link 'http://example.com', 'Example Web Page', 'These domain names are reserved...'
#soup.new_image 'http://chaosradio.ccc.de/chaosradio-logo-transparent-300.png', 'Chaosradio Logo'
#soup.new_text 'Lorem ipsum dolor sit amet, consectetuer.', 'Lorem ipsum'
#soup.new_quote 'Ipsum dolor lorem sit amet, consectetuer.', 'consectetuer'
#soup.new_video 'http://www.youtube.com/watch?v=dMH0bHeiRNg', 'Evolution of Dance'
#

################################ Begin rBot Code ################################

class SoupIoPlugin < Plugin
  def initialize
    super
    class << @registry
      def store(val)
        val
      end
      def restore(val)
        val
      end
    end
  end
  
  # return a help string when the bot is asked for help on this plugin
  def help(plugin, topic="")
    return 'soup.io plugin: ' +
    'soup identify <username> <password>, ' +
    'soup login => Forces a new Soup.io login if the session-id is lost/invalid, ' +
    'soup link <url> [<title>], ' +
    'soup image <url> [<description>], ' +
    'soup text <text>, ' +
    'soup quote <source>: <quote>, ' +
    'soup video <youtube-url> [<description>]'
  end
  
  # return logged in SoupIoClass Object or false
  def get_soupio_class(m)
    unless @registry.has_key?(m.sourcenick + "_password") && @registry.has_key?(m.sourcenick + "_username")
      m.reply "you must identify in query using 'soup identify [username] [password]'"
      return false
    end

    user = @registry[m.sourcenick + "_username"]
    pass = @registry[m.sourcenick + "_password"]
    sessid = @registry[m.sourcenick + "_sessid"]
    domain = @registry[m.sourcenick + "_domain"]
    
    soup = SoupIoClass.new(user, pass, domain, sessid)
    
    if soup.sessid == nil then
      m.reply 'Failed login. Try again to identify.'
      return false
    end
    
    @registry[m.sourcenick + "_domain"] = soup.domain
    @registry[m.sourcenick + "_sessid"] = soup.sessid
    
    return soup
  end

  # The Soup.io SessionId Cookie has no real Expire-Date, 
  # but if something went wrong this sould be useful
  def force_relogin(m, params)
    # clear registry for domain and session id
    @registry[m.sourcenick + "_domain"] = nil
    @registry[m.sourcenick + "_sessid"] = nil
    
    m.okay if get_soupio_class(m)
  end
  
  def new_link(m, params)
    soup = get_soupio_class(m)
    return false if soup == false

    m.okay if soup.new_link(params[:url], params[:title])
  end
  
  def new_image(m, params)
    soup = get_soupio_class(m)
    return false if soup == false
    
    m.okay if soup.new_image(params[:url], params[:description])
  end
  
  def new_text(m, params)
    soup = get_soupio_class(m)
    return false if soup == false
    
    m.okay if soup.new_text(params[:text])
  end
  
  def new_quote(m, params)
    soup = get_soupio_class(m)
    return false if soup == false
    
    m.okay if soup.new_quote(params[:quote], params[:source])
  end
  
  def new_video(m, params)
    soup = get_soupio_class(m)
    return false if soup == false
    
    m.okay if soup.new_video(params[:url], params[:description])
  end
  
  # set user and pass for soup.io
  def identify(m, params)
    @registry[m.sourcenick + "_username"] = params[:username].to_s
    @registry[m.sourcenick + "_password"] = params[:password].to_s
    @registry[m.sourcenick + "_domain"] = nil
    @registry[m.sourcenick + "_sessid"] = nil
    
    m.okay if get_soupio_class(m)
  end
end

# create an instance of our plugin class and register for the "length" command
plugin = SoupIoPlugin.new
plugin.map 'soup identify :username :password', :action => "identify", :public => false
plugin.map 'soup login', :action => "force_relogin"

plugin.map 'soup link :url [*title]', :action => "new_link", :threaded => true
plugin.map 'soup image :url [*description]', :action => "new_image", :threaded => true
plugin.map 'soup text *text', :action => "new_text", :threaded => true
plugin.map 'soup quote *source: *quote', :action => "new_quote", :threaded => true
plugin.map 'soup video :url [*description]', :action => "new_video", :threaded => true

=begin
Some testing commands...
soup link http://example.com Example Web Page
soup image http://chaosradio.ccc.de/chaosradio-logo-transparent-300.png Chaosradio Logo
soup text Lorem ipsum dolor sit amet
soup quote Lorem ipsum: Lorem ipsum dolor sit amet
soup video http://www.youtube.com/watch?v=dMH0bHeiRNg Evolution of Dance
=end

