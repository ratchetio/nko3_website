require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)
util = require 'util'
postageapp = require('postageapp')(env.secrets.postageapp)

Vote = mongoose.model 'Vote'
Person = mongoose.model 'Person'

Person.find { role: 'judge', email: /@/, twitterScreenName: /\w/ }, (err, judges) ->
  throw err if err
  judges.forEach (judge) ->
    Vote.count { personId: judge.id }, (err, count) ->
      throw err if err
      votes_left = 10 - count
      if votes_left > 0
        util.log "Sending 'judge_nag_two' to '#{judge.email}' (#{count})".yellow
        postageapp.apiCall judge.email, 'judge_nag_two', null, null,
          first_name: judge.name.split(/\s/)[0]
          votes_left: if votes_left is 1 then '1 vote' else "#{votes_left} votes"
      else util.log "Skipping '#{judge.email}' (#{count})"
