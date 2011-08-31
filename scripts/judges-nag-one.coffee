require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)
util = require 'util'
postageapp = require('postageapp')(env.secrets.postageapp)

Vote = mongoose.model 'Vote'
Person = mongoose.model 'Person'

Person.find { role: 'judge', email: /@/, twitterScreenName: /gerad/ }, (err, judges) ->
  throw err if err
  judges.forEach (judge) ->
    Vote.count { personId: judge.id }, (err, count) ->
      throw err if err
      if count is 0
        util.log "Sending 'judge_nag_one' to '#{judge.email}' (#{count})".yellow
        postageapp.apiCall judge.email, 'judge_nag_one', null, null,
          id: judge.id
          first_name: judge.name.split(/\s/)[0]
      else util.log "Skipping '#{judge.email}' (#{count})"
