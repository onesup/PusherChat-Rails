class Chat < ActiveRecord::Base
  has_many :messages
  #has_many :chat_users, :through => :messages
end
