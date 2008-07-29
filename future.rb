#
#   future.rb - 
#   	$Release Version: $
#   	$Revision: 1.1 $
#   	$Date: 1997/08/08 00:57:08 $
#   	by Keiju ISHITSUKA(Penta Advanced Labrabries, Co.,Ltd)
#
# --
#
#   v = DeepConnect::future{exp}
#   v = DeepConnect::Future.future{exp}
#   
#

require "thread"
require "delegate"

module DeepConnect
  def future(&block)
    Future.new(&block)
  end
  module_function :future

  class Future < Delegator

    NULLVALUE = :__FUTURE_NULLVALUE__

    def self.future(&block)
      Futre.new(&block)
    end

    def initialize(&block)
      super(@value = NULLVALUE)
      @value_mutex = Mutex.new
      @value_cv = ConditionVariable.new
      Thread.start do
	@value = yield
	@value_cv.broadcast
      end
    end

    def value
      @value_mutex.synchronize do
	while @value == NULLVALUE
	  @value_cv.wait(@value_mutex)
	end
      end
      @value
    end
    alias __getobj__ value

    def value?
      @value != NULLVALUE
    end

    def inspect
      if @value == NULLVALUE
	"#<#{self.class}: NULL>"
      else
	"#<#{self.class}: #{@value.inspect}>"
      end
    end
  end
end

  