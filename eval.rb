# Based on Kirby 4.2 by Evan Weaver (http://blog.evanweaver.com).
# Implemented for #ruby-it@freenode by Marcello Barnaba (vjt@openssl.it).
# Released under the terms of the Academic Free License (AFL) v. 3.0.
#
# version 0.5, Fri Jan 18 01:57:16 CET 2008 -vjt
#

=begin rdoc
In-channel commands:
<tt>>> CODE</tt>:: evaluate code in IRB.
<tt>!reset_irb</tt>:: get a clean IRB session.
=end

require 'open-uri'
require 'cgi'

class Eval < Plugin
  def initialize
    super
    try_reset
  end

  def reset_irb(m, params)
    try_reset
    try_log "#{m.source} RESET"
    m.reply "began new session"
  end

  def listen(m)
    return unless m.respond_to? :message
    return unless m.message =~ /^>>\s*(.+)/

    try_eval($1).select{|e| e !~ /^\s+from .+\:\d+(\:|$)/}.each {|e| m.reply e} rescue m.reply "session error"
    try_log "#{m.source} #{m.message}"
  end

  protected
  def try_eval(s)
    try_reset and return ['began new session'] if s.strip == "exit"
    result = open("http://tryruby.hobix.com/irb?cmd=#{CGI.escape(s)}", 
                  {'Cookie' => "_session_id=#{@session}"}).read
    result[/^Your session has been closed/] ? ['session error'] : result.split("\n")
  end

  def try_reset
    @session = try_eval("!INIT!IRB!")
  end

  def try_log(s)
    @bot.irclog s, '_eval_log'
  end
end

plugin = Eval.new
plugin.map 'reset_irb',  :action => 'reset_irb'

# EOF