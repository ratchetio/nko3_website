load = ->
  ws = nko.ws

  # reload the page after ~10 seconds (if you're on the index page)
  ws.on 'reload', ->
    setTimeout ->
      if window.location.pathname is '/'
        window.location.reload()
    , (Math.random() * 10000)

  ws.on 'updateStats', (json) ->
    console.dir(json)

  # update the stats billboard on the team page
  ws.on 'updateTeamStats', (json) ->
    { teamId, stats } = json
    $stats = $(".team-stats[data-team-id=#{teamId}]")
    for k, v of stats
      $stats.find(".#{k} .number").text(v)

$(load)
# note no pjax load here
