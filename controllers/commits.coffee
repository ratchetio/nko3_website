util = require 'util'

module.exports = (app) ->
  Team = app.db.model 'Team'

  (req, res, next) ->
    return next() unless req.method is 'POST' and m = req.url.match /^\/teams\/(.+)\/commits$/

    try
      code = decodeURIComponent m[1]
    catch err
      return next(err)

    Team.findOne code: code, (err, team) ->
      return next err if err
      return next 404 unless team

      util.log "#{'POST-RECEIVE'.magenta} #{team.name} (#{team.id})"
      req.session.destroy()

      try
        $inc = pushes: 1, commits: req.body.repository.commits.length
      catch e
        return next(e)

      app.stats.increment $inc
      team.incrementStats $inc, (err, team) ->
        return next(err) if err
        app.events.emit 'updateTeamStats', team
        res.send 200
