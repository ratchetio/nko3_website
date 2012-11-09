_ = require 'underscore'
m = require './middleware'
util = require 'util'

module.exports = (app) ->
  Team = app.db.model 'Team'
  Deploy = app.db.model 'Deploy'

  (req, res, next) ->
    return next() unless req.method is 'POST' and req.url is '/deploys'

    try
      slug = req.body.user.replace('nko3-', '')
    catch err
      return next(err)

    Team.findBySlug slug, (err, team) ->
      return next err if err
      return next 404 unless team

      util.log "#{'DEPLOY'.magenta} #{team.name} (#{team.id})"
      req.session.destroy()

      attr = _.clone req.body
      attr.teamId = team.id
      attr.remoteAddress = req.socket.remoteAddress

      # save the deploy in the db
      deploy = new Deploy attr
      deploy.save (err, deploy) ->
        if err
          util.error err.toString().red
          return res.end JSON.stringify(err)

        # increment overall/team deploy count
        $inc = deploys: 1
        app.stats.increment $inc
        team.incrementStats $inc, (err, team) ->
          return next(err) if err

          app.events.emit 'updateTeamStats', team
          app.events.emit 'deploy', deploy, req.team

          res.end JSON.stringify(deploy)
