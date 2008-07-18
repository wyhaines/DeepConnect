
require "e2mmap"

module DeepConnect
  extend Exception2MessageMapper

  def_exception :NoServiceError, "No such service(%s)"
  def_exception :CantSerializable, "%s�ϥ��ꥢ�饤���Ǥ��ޤ���"
  def_exception :CantDup, "%s��dup�Ǥ��ޤ���"
  def_exception :CantDeepCopy, "%s��deep copy�Ǥ��ޤ���"

  def_exception :SessionServiceStopped, "Session service stopped"
  def_exception :DisconnectClient, "%s����³���ڤ�ޤ���"

  def_exception :InternalError, "DeepConnect internal error(%s)"
  def_exception :ProtocolError, "Protocol error!!"

  def self.InternalError(message)
    DeepConnect.Raise InternalError, message
  end
end
