require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)

Person = mongoose.model 'Person'

console.log "name\temail"
Person.find { role: 'judge', email: /@/, }, (err, judges) ->
  throw err if err
  i = judges.length
  judges.forEach (judge) ->
    console.log "#{judge.name ? ""}\t#{judge.email.replace(/\.nodeknockout\.com$/, '')}"
    mongoose.connection.close() if --i is 0
