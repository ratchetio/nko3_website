require 'colors'
redis = require 'redis'
util = require 'util'
client = redis.createClient()

client.on 'error', (err) ->
  throw err

client.keys '*', (err, keys) ->
  keys.forEach (key) ->
    util.log "Expiring #{key}..."
    client.expire key, 600
