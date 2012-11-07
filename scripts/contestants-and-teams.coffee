require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)

Person = mongoose.model 'Person'

console.log "name\temail\tteam_id"
Person.find { role: 'contestant', email: /@/, }, (err, people) ->
  throw err if err
  i = people.length
  people.forEach (person) ->
    person.team (err, team) ->
      throw err if err
      if team?
        console.log "#{person.name ? ""}\t#{person.email.replace(/\.nodeknockout\.com$/, '')}\t#{team}"
      mongoose.connection.close() if --i is 0
