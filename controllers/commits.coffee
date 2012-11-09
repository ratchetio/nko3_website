util = require 'util'

module.exports = (app) ->
  Team = app.db.model 'Team'

  (req, res, next) ->
    return next() unless req.method is 'POST' and m = req.url.match /^\/teams\/(.+)\/commits$/
    console.dir req.body

    # custom error handler (since the default one dies w/o session)
    error = (err) ->
      util.error err.toString().red
      res.end JSON.stringify(err)

    try
      req.session.destroy()
      code = decodeURIComponent m[1]
    catch err
      return error(err)

    Team.findOne code: code, (err, team) ->
      return error(err) if err
      return res.send(404) unless team

      util.log "#{'POST-RECEIVE'.magenta} #{team.name} (#{team.id})"

      try
        $inc = pushes: 1, commits: req.body.repository.commits.length
      catch e
        return next(e)

      app.stats.increment $inc
      team.incrementStats $inc, (err, team) ->
        return next(err) if err
        app.events.emit 'updateTeamStats', team
        res.send 200
