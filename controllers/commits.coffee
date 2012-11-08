util = require 'util'

module.exports = (app) ->
  Team = app.db.model 'Team'

  (req, res, next) ->
    if req.method is 'POST' and m = req.url.match /^\/teams\/(.+)\/commits$/
      util.log "#{'POST-RECEIVE'.magenta} #{req.url}"
      code = decodeURIComponent m[1]
      Team.findOne code: code, (err, team) ->
        return next err if err
        return next 404 unless team
        try
          $inc = pushes: 1, commits: req.body.repository.commits.length
        catch e
          return next(e)

        app.stats.increment $inc
        team.incrementStats $inc, (err, team) ->
          return next(err) if err
          app.events.emit 'updateTeamStats', team
          res.send 200
    else next()
