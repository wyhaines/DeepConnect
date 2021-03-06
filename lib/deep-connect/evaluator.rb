# encoding: UTF-8
#
#   evaluator.rb - 
#   	Copyright (C) 1996-2010 Keiju ISHITSUKA
#				(Penta Advanced Labrabries, Co.,Ltd)
#


require "deep-connect/event"
require "deep-connect/exceptions"

module DeepConnect
  class Evaluator
    def initialize(org)
      @organizer = org
    end

    def evaluate_request(session, event)
      begin
	if @organizer.shallow_connect?
	  if !(mspec = Organizer::method_spec(event.receiver, event.method)) or
	      !mspec.interface?
	    DC.Raise NoInterfaceMethod, event.receiver.class, event.method
	  end
	end
	ret = event.receiver.send(event.method, *event.args)
	unless event.kind_of?(Event::NoReply)
	  session.accept event.reply(ret)
	end
#      rescue SygnalException
#	puts "Info: catch"
#	
      rescue SystemExit
	raise
      rescue Exception
#p event.receiver.class
#p event.method
#p $!
#p $@
	unless event.kind_of?(Event::NoReply)
	  session.accept event.reply(ret, $!)
	end
      end
    end

    def evaluate_iterator_request(session, event)
      begin 
	if @organizer.shallow_connect?
	  if !(mspec = Organizer::method_spec(event.receiver, event.method)) or
	      !mspec.interface?
	    DC.Raise NoInterfaceMethod, event.receiver.class, event.method
	  end
	end
	fin = event.receiver.send(event.method, *event.args){|*args|
	  begin
#  	    if args.size == 1 && args.first.kind_of?(Array)
#  	      args = args.first
#  	    end
	    callback_req = session.block_yield(event, args)

	    case callback_req.result_event
	    when Event::IteratorCallBackReplyBreak
	      break callback_req.result
	    else
	      callback_req.result
	    end
	  rescue
	    # ここ内部エラーじゃないなぁ...
	    if Conf.DEBUG
	      puts "INFO: BLOCK YIELD EXCEPTION:"
	      puts  "\t#{$!}"
	      $@.each{|l| puts "\t#{l}"}
	    end
	    raise
	  end
	}
	session.accept event.reply(fin)
      rescue SystemExit
	raise
      rescue Exception
	session.accept event.reply(fin, $!)
      end
    end

    def evaluate_block_yield(session, ev)
      if @organizer.shallow_connect?
	# yield が許されているかチェック
      end
      begin
	args = ev.args

	if ev.block.arity > 1
	  begin
	    if args.size == 1 && args.first.__deep_connect_reference?
	      if args.first.kind_of?(Array)
		args = args.first.dc_dup
	      end
	    end
	  rescue
	    p $!, $!
	    raise
	  end
	end
	ret = ev.block.call(*args)
	session.accept ev.reply(ret)
      rescue LocalJumpError
	exp = $!
	case exp.reason
	when :break
	  session.accept ev.reply(ret, 
				  exp.exit_value, 
				  Event::IteratorCallBackReplyBreak)
	else
	  session.accept ev.reply(ret, exp)
	end
      rescue Exception
	exp = $!
	session.accept e = ev.reply(ret, exp)
      end
    end

    def evaluate_mq_request(session, event, callback)
      begin
	if @organizer.shallow_connect?
	  if !(mspec = Organizer::method_spec(event.receiver, event.method)) or
	      !mspec.interface?
	    DC.Raise NoInterfaceMethod, event.receiver.class, event.method
	  end
	end
	ret = event.receiver.send(event.method, *event.args)
	if callback 
	  callback.asynchronus_send(:call, ret, nil)
	  callback.release
	end
      rescue SystemExit
	raise
      rescue Exception
	if callback
p event.receiver.class
p event.method
p $!
p $@
          callback.asynchronus_send(:call, ret, $!)
	  callback.release
	end
      end
    end
  end
end
