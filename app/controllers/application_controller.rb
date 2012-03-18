class ApplicationController < ActionController::Base
  # Add IE support to accept cookies when using pusher chat inside an iframe
  #before_filter { response.headers['P3P'] = %q|CP="HONK"| }
end
