require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)
require('../lib/mongo-log')(mongoose.mongo)
util = require 'util'
async = require 'async'
request = require 'request'

url = "https://visnup:#{process.env.PASSWORD}@api.github.com"

Team = mongoose.model 'Team'
Person = mongoose.model 'Person'

queue = async.queue (team, next) ->
  # skip empty teams
  return next() if team.peopleIds.length is 0

  async.waterfall [
    (next) ->                 # create repo
      request.post
        url: "#{url}/orgs/nko3/repos"
        json:
          name: team.slug
          homepage: "http://2012.nodeknockout.com/teams/#{team}"
          private: true
      , next
    (res, body, next) ->      # create team
      request.post
        url: "#{url}/orgs/nko3/teams"
        json:
          name: team.name
          repo_names: [ "nko3/#{team.slug}" ]
          permission: 'admin'
      , next
    (res, body, next) ->      # save team id
      team.github ||= body
      team.save next
    (team, n, next) ->        # get people
      Person.find { _id: { $in: team.peopleIds } }, (err, people) ->
        next err, team, people
    (team, people, next) ->   # add members
      async.forEach people, (person, next) ->
        request.put
          url: "#{url}/teams/#{team.github.id}/members/#{person.github.login}"
          json: {}
        , next
      , next
  ], next
, 5

Team.find { slug: 'fortnight-labs' }, (err, teams) ->
  throw err if err
  queue.push teams

queue.drain = ->
  mongoose.connection.close()
  console.log 'done!'
