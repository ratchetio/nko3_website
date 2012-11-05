unless process.env.LOGIN
  console.log "Usage: LOGIN=[github username]:[password] coffee #{__filename}"
  process.exit(1)

mongoose = require('../models')(require('../config/env').mongo_url)
#require('../lib/mongo-log')(mongoose.mongo)

spawn = require('child_process').spawn
async = require 'async'
request = require 'request'

github = (path) -> "https://#{process.env.LOGIN}@api.github.com/#{path}"

Team = mongoose.model 'Team'
Person = mongoose.model 'Person'

queue = async.queue (team, next) ->
  # skip empty teams
  return next() if team.peopleIds.length is 0

  async.waterfall [
    (next) ->                 # create repo
      request.post
        url: github 'orgs/nko3/repos'
        json:
          name: team.slug
          homepage: "http://2012.nodeknockout.com/teams/#{team}"
          private: true
      , next
    (res, body, next) ->      # create push hook
      return next(null, null, null) unless body.id
      request.post
        url: github "repos/nko3/#{team.slug}/hooks"
        json:
          name: 'web'
          active: true
          config:
            url: "http://nodeknockout.com/teams/#{team.code}/commits"
            content_type: 'json'
      , next
    (res, body, next) ->      # create team
      request.post
        url: github 'orgs/nko3/teams'
        json:
          name: team.name
          repo_names: [ "nko3/#{team.slug}" ]
          permission: 'admin'
      , next
    (res, body, next) ->      # save team id
      team.github = body if body.id
      unless team.github
        console.warn "!!! Proceeding without accurate GitHub team id"
        team.github = { id: 0 }
      team.save next
    (team, n, next) ->        # get people
      Person.find { _id: { $in: team.peopleIds } }, (err, people) ->
        next err, team, people
    (team, people, next) ->   # add members
      async.forEach people, (person, next) ->
        request.put
          url: github "teams/#{team.github.id}/members/#{person.github.login}"
          json: {}
        , next
      , next
    (next) ->                 # seed repo
      createRepo = spawn './create-repo.sh',
        [ team.slug, team.code, team.name, team.github.id ],
        cwd: __dirname
      createRepo.stdout.on 'data', (s) -> console.log s.toString()
      createRepo.on 'exit', -> next()
  ], next
, 5 # workers

Team.find { slug: 'fortnight-labs' }, (err, teams) ->
  throw err if err
  queue.push teams

queue.drain = -> mongoose.connection.close()
