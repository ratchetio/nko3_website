mongoose = require 'mongoose'

TeamLimitSchema = module.exports = new mongoose.Schema
  limit:
    type: Number
    required: true
  effectiveAt:
    type: Date
    required: true
TeamLimitSchema.plugin require('../lib/use-timestamps')
TeamLimitSchema.index effectiveAt: -1

# class methods

lastLimit = null
TeamLimitSchema.static 'current', (next) ->
  now = new Date

  # only check every hour, unless we're near 0:00/12:00 UTC
  if lastLimit?.updatedAt > now - (1000*60*60) and not @aroundMeridian(now)
    next null, lastLimit.limit
  else
    TeamLimit.findOne { effectiveAt: { $lte: now } }, {}, { sort: [[ 'effectiveAt', -1 ]] }, (err, limit) ->
      return next err if err

      limit ||= new TeamLimit limit: 0, effectiveAt: now # default to 0
      limit.updatedAt = now
      limit.save()

      lastLimit = limit

      next null, limit.limit

TeamLimitSchema.static 'aroundMeridian', (now) ->
  [h, m] = [now.getUTCHours(), now.getUTCMinutes()]
  (h == 11 && m > 54) || (h == 12 && m < 5) ||  # 11:55 - 12:05
  (h == 23 && m > 54) || (h ==  0 && m < 5)     # 23:55 - 00:05

TeamLimit = mongoose.model 'TeamLimit', TeamLimitSchema
