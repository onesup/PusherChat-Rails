typing_status = (status) ->
  $.post "/api/typing_status",
    chat_id: chat_id
    status: status
updateCount = (i) ->
  count = parseInt($("#room_count").text())
  $("#room_count").text count + i
send_message = ->
  if $("#message").val() is ""
    alert "Please enter a message..."
    $("#message").focus()
    return false
  $("#message").css color: "#000000"
  message = $("#message").val()
  username = $("#username").val()
  $("#loading").fadeIn()
  $("#message-overlay").fadeIn 200
  $("#message").blur()
  $.post "/api/post_message",
    chat_id: chat_id
    message: message
    , (response) ->
      $("#message").val ""
      $("#message-overlay").fadeOut 150
      $("#message").focus()
      $("#loading").fadeOut()
      is_typing_currently = false
      typing_status false
scrollToTheTop = ->
  $("#messages").scrollTop 20000000
replaceURLWithHTMLLinks = (text) ->
  exp = /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/g
  text.replace exp, "<a href='$1' target='_blank'>$1</a>"
hasFocus = true
people = []
window.onblur = ->
  hasFocus = false

window.onfocus = ->
  hasFocus = true
  document.title = "Pusher Chat"

is_typing_currently = false
browser_audio_type = ""
$(document).ready ->
  return  if typeof Pusher is "undefined"
  audio = document.createElement("audio")
  audio_types = [ "ogg", "mpeg", "wav" ]
  if typeof audio.canPlayType is "function"
    for type of audio_types
      type_name = audio_types[type]
      if audio.canPlayType("audio/" + type_name) is "yes" or audio.canPlayType("audio/" + type_name) is "maybe"
        browser_audio_type = type_name
        break
  Pusher.channel_auth_endpoint = "/api/authenticate?user_id=" + user_id
  socket = new Pusher(PUSHER_KEY)
  presenceChannel = socket.subscribe("presence-" + channel)
  presenceChannel.bind "pusher:subscription_succeeded", (member_list) ->
    updateCount member_list.count

  presenceChannel.bind "pusher:member_added", (member) ->
    $("#messages").append "<li class=\"note\"><strong>" + member.chat_user.nickname + "</strong> joined the chat.</li>"
    scrollToTheTop()
    updateCount 1

  presenceChannel.bind "pusher:member_removed", (member) ->
    $("#messages").append "<li class=\"note\"><strong>" + member.chat_user.nickname + "</strong> left the chat.</li>"
    scrollToTheTop()
    updateCount -1

  presenceChannel.bind "updated_nickname", (member) ->
    if member.user_id is user_id
      $("#messages").append "<li class=\"note\">You have updated your nickname to <strong>" + member.nickname + "</strong>.</li>"
    else
      $("#messages").append "<li class=\"note\"><strong>" + member.old_nickname + "</strong> updated their nickname to <strong>" + member.nickname + "</strong>.</li>"
    scrollToTheTop()

  presenceChannel.bind "send_message", (message) ->
    you = ""
    if user_id is message.user.id
      you = "you "
      $("#message-overlay").fadeOut 150
    else
      $("#messages #is_typing_" + message.user.id).hide()
      unless hasFocus
        document.title = "New Message! - Pusher Chat"
        unless browser_audio_type is ""
          pop = document.createElement("audio")
          if browser_audio_type is "mpeg"
            pop.src = "/sounds/pop.mp4"
          else
            pop.src = "/sounds/pop." + browser_audio_type
          unless pop.src is ""
            pop.load()
            pop.play()
    $("#messages").append "<li class=\"" + you + "just_added_id_" + message.id + "\" style=\"display:none;\"><strong>" + message.user.nickname + "</strong> said:<br />" + replaceURLWithHTMLLinks(message.message) + "</li>"
    $("#messages li.just_added_id_" + message.id).fadeIn()
    scrollToTheTop()

  presenceChannel.bind "typing_status", (notification) ->
    return false  if notification.user.id is user_id
    if notification.status is "true"
      $("#messages").append "<li class=\"note\" id=\"is_typing_" + notification.user.id + "\"><strong>" + notification.user.nickname + "</strong> is typing...</li>"
    else
      $("#messages #is_typing_" + notification.user.id).remove()
    scrollToTheTop()

  $("#loading").fadeOut()
  $("#message").removeAttr "disabled"
  scrollToTheTop()
  $("#message").keydown (e) ->
    if e.keyCode is 13
      send_message()
      false

  timout_function = ->
    is_typing_currently = false
    typing_status false

  typing_end_timeout = undefined
  $("#message").keyup ->
    clearTimeout typing_end_timeout
    if $(this).val() is "" and is_typing_currently
      typing_end_timeout = setTimeout(timout_function, 1500)
    else
      unless is_typing_currently
        is_typing_currently = true
        typing_status true

  old_nickname = ""
  $("#editNickname").click ->
    $("#title").fadeOut 200
    $("#nickname").fadeIn 200
    $("#saveNickname").fadeIn 200
    $(this).hide()
    old_nickname = $("#nickname").val()
    false

  $("#saveNickname").click ->
    $("#nickname").attr "disabled", "disabled"
    unless $("#nickname").val() is old_nickname
      $.post "/api/update_nickname/",
        chat_id: chat_id
        user_id: user_id
        nickname: $("#nickname").val()
        , (response) ->
          alert "There was an error updating your nickname, please try again."  unless response is "SAVED"
          $("#nickname").hide()
          $("#nickname").attr "disabled", ""
          $("#editNickname").fadeIn 200
          $("#title").fadeIn 200
          $("#saveNickname").hide()
    else
      $("#nickname").hide()
      $("#nickname").attr "disabled", ""
      $("#editNickname").fadeIn 200
      $("#title").fadeIn 200
      $("#saveNickname").hide()
    false

  text = "Type your message here and hit enter..."
  $("#message").focus(->
      $(this).val ""  if $(this).val() is text
  ).blur ->
    $(this).val text  if $(this).val() is ""