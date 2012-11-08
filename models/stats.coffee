{ EventEmitter } = require 'events'

# singleton for handling stats

class Stats extends EventEmitter
  constructor: ->
    @pushes = 0
    @commits = 0
    @deploys = 0

  increment: (stats) ->
    for k, v of stats
      @[k] += v
    @emit 'change', this

module.exports = Stats
