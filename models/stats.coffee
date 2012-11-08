{ EventEmitter } = require 'events'

# singleton for handling stats

class Stats extends EventEmitter
  keys: ['commits', 'pushes', 'deploys']
  constructor: (@db, callback) ->
    # initially set all counts to 0
    @zeroCounts()

    # then reset the in-memory count based on what's in the db
    @resetCounts(callback)

  zeroCounts: ->
    @[k] = 0 for k in @keys

  resetCounts: (callback) ->
    # calculate the totals from what's in the db
    @aggregate (err, stats) =>
      return callback(err) if err

      # reset the counts by zeroing everything then incrementing with the new
      # totals
      @zeroCounts()
      @increment(stats)

      callback()

  # lame, manual aggregation
  aggregate: (callback) ->
    res = {}
    res[k] = 0 for k in @keys
    @db.model('Team').find stats: { $exists: 1 }, 'stats', (err, teams) =>
      return callback(err) if err
      for team in teams
        res[k] += (team.stats[k] ? 0) for k in @keys
      console.dir(res)
      callback null, res

  # aggregate using the mongo aggregation framework
  # our version of mongoose doesn't support this, and I'm scared to upgrade
  # aggregate: (callback) ->
  #   $group = _id: null
  #   for own k, v of @ when k isnt 'db'
  #     # commits: { '$sum': '$stats.commits' }
  #     $group[k] = { $sum: "$stats.#{k}" }
  #   console.dir($group)
  #   @db.model('Team').aggregate $group: $group, (err, res) =>
  #     return callback(err) if err
  #     try
  #       res = res[0]
  #       delete res._id
  #       callback(null, res)
  #     catch e
  #       return callback(e)
  #     callback()

  increment: (stats) ->
    for k in @keys
      @[k] += (stats[k] ? 0)
    @emit 'change', @stats()

  stats: ->
    res = {}
    res[k] = @[k] for k in @keys
    res

module.exports = Stats
