env = require '../config/env'
mongoose = require('../models')(env.mongo_url)

Team = mongoose.model 'Team'

Team.find {}, (err, teams) ->
  throw err if err
  json = teams.map (team) ->
    username: "nko3-#{team.slug}"
    password: team.code
    email: "team+#{team.slug}@nodeknockout.com"
  console.log json

  mongoose.connection.close()
