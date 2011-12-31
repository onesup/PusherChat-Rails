require 'pusher'
require 'tiny'

config = YAML.load_file(File.join(Rails.root, "config", "pusher.yml"))[Rails.env]

# Set your pusher API credentials in config/pusher.yml
Pusher.app_id = config["app_id"]
Pusher.key = config["key"]
Pusher.secret = config["secret"]
