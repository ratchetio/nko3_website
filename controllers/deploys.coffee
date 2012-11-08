_ = require 'underscore'
m = require './middleware'
util = require 'util'

module.exports = (app) ->
  Team = app.db.model 'Team'
  Deploy = app.db.model 'Deploy'

  (req, res, next) ->
    return next() unless req.method is 'POST' and req.url is '/deploys'

    slug = req.body.user.replace('nko3-', '')
    Team.findBySlug slug, (err, team) ->
      return next err if err
      return next 404 unless team

      util.log "#{'DEPLOY'.magenta} #{team.name} (#{team.id})"
      req.session.destroy()

      attr = _.clone req.body
      attr.teamId = team.id
      attr.remoteAddress = req.socket.remoteAddress

      deploy = new Deploy attr
      deploy.save (err, deploy) ->
        if err
          util.error err.toString().red
          return res.end JSON.stringify(err)
        res.end JSON.stringify(deploy)
        app.events.emit 'deploy', deploy, req.team
