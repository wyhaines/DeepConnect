#
#   serialize.rb - 
#   	$Release Version: $
#   	$Revision: 1.1 $
#   	$Date: 1997/08/08 00:57:08 $
#   	by Keiju ISHITSUKA(Penta Advanced Labrabries, Co.,Ltd)
#
# --
#
#   
#

require "deep-connect/deep-connect"
require "deep-connect/reference"

module DeepConnect
  UNSERIALIZABLE_CLASSES = [
    StopIteration,
    Enumerable::Enumerator,
    Binding,
    UnboundMethod,
    Method,
    Proc,
    Dir,
    File,
    IO,
    ThreadGroup,
    Continuation,
    Thread,
    Data,
    Class,
    Module,
  ]
  UNSERIALIZABLE_CLASS_SET = {}
  UNSERIALIZABLE_CLASSES.each do|k|
    UNSERIALIZABLE_CLASS_SET[k] = k
  end
end

class Object 
  def self.deep_connect_materialize_val(deep_space, value)
    obj = allocate
    value.each do |v, o|
      obj.instance_variable_set(v, DeepConnect::Reference.materialize(deep_space, *o))
    end
    obj
  end

  def deep_connect_serialize_val(deep_space)
    if DeepConnect::UNSERIALIZABLE_CLASS_SET.include?(self.class)
      raise "#{self.class}はシリアライズできません"
    end
    vnames = instance_variables
    vnames.collect{|v| 
      [v, 
	DeepConnect::Reference.serialize(deep_space, instance_variable_get(v))]}
  end


  def deep_connect_dup
    if DeepConnect::UNSERIALIZABLE_CLASS_SET.include?(self.class)
      raise "#{self.class}はdupできません"
    end
    self
  end
  alias dc_dup deep_connect_dup
  DeepConnect.def_method_spec(self, :rets=>"VAL", :method=>:deep_connect_dup)
  DeepConnect.def_method_spec(self, :rets=>"VAL", :method=>:dc_dup)

  def deep_connect_deep_copy
    if DeepConnect::UNSERIALIZABLE_CLASS_SET.include?(self.class)
      raise "#{self.class}はdeep_copyできません"
    end
    self
  end
  alias dc_deep_copy deep_connect_deep_copy
  DeepConnect.def_method_spec(self, :rets=>"DVAL", :method=>:deep_connect_deep_copy)
  DeepConnect.def_method_spec(self, :rets=>"DVAL", :method=>:dc_deep_copy)
end

class Array
  def self.deep_connect_materialize_val(deep_space, value)
    ary = new
    value.each{|e| ary.push DeepConnect::Reference.materialize(deep_space, *e)}
    ary
  end

  def deep_connect_serialize_val(deep_space)
    collect{|e| DeepConnect::Reference.serialize(deep_space, e)}
  end

end

class Hash
  def self.deep_connect_materialize_val(deep_space, value)
    hash = new
    value.each do |k, v| 
      key = DeepConnect::Reference.materialize(deep_space, *k)
      value = DeepConnect::Reference.materialize(deep_space, *v)
      hash[key] = value
    end
    hash
  end

  def deep_connect_serialize_val(deep_space)
    collect{|k, v| 
      [DeepConnect::Reference.serialize(deep_space, k), 
	DeepConnect::Reference.serialize(deep_space, v)]}
  end

end

class Struct
  def self.deep_connect_materialize_val(deep_space, value)
    new(*value.collect{|e| DeepConnect::Reference.materialize(deep_space, *e)})
  end

  def deep_connect_serialize_val(deep_space)
    to_a.collect{|e| DeepConnect::Reference.serialize(deep_space, e)}
  end
end


