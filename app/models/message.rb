class Message < ActiveRecord::Base
  belongs_to :chat
  belongs_to :chat_user, :foreign_key => :user_id
end
