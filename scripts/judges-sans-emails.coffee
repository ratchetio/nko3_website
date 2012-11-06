require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)

Person = mongoose.model 'Person'

console.log "handle\temail"
Person.find { role: 'judge' }, (err, judges) ->
  throw err if err
  i = judges.length
  judges.forEach (judge) ->
    unless /@/.test(judge.email)
      console.log """
        @#{judge.twitterScreenName ? ""} can you update the email address on
        your judging profile? http://nodeknockout.com/judges/#{judge}/edit
        (requires Twitter auth). Thanks!
        """.replace(/\n+/g, ' ')
    mongoose.connection.close() if --i is 0
