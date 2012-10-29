_ = require 'underscore'
mongoose = require 'mongoose'
env = require '../config/env'

ServiceSchema = module.exports = new mongoose.Schema
  name: String
  description: String

ServiceSchema.static 'sorted', (callback) ->
  Service.find (error, services) ->
    return callback(error) if error
    callback null, _.sortBy(services, (s) -> s.name.toLowerCase())

ServiceSchema.static 'asObject', (callback) ->
  Service.find (error, services) ->
    return callback(error) if error
    obj = {}
    obj[s.name] = s.description for s in services
    callback null, obj


Service = mongoose.model 'Service', ServiceSchema
