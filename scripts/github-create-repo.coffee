mongoose = require('../models')(require('../config/env').mongo_url)
#require('../lib/mongo-log')(mongoose.mongo)

spawn = require('child_process').spawn
async = require 'async'

Team = mongoose.model 'Team'

createTeam = (team, next) ->
  # skip empty teams
  return next() if team.peopleIds.length is 0

  console.log team.slug, 'seed repo'
  createRepo = spawn './create-repo.sh',
    [ team.slug, team.code, team.name, team.github.id ],
    cwd: __dirname
  createRepo.stdout.on 'data', (s) -> console.log s.toString()
  createRepo.on 'exit', -> next()

Team.find { slug: {$in: process.argv[2..]} }, (err, teams) ->
  throw err if err
  async.forEachSeries teams, createTeam, (err) ->
    throw err if err
    mongoose.connection.close()
