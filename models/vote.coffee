_ = require 'underscore'
mongoose = require 'mongoose'
ObjectId = mongoose.Schema.ObjectId
Person = mongoose.model 'Person'
util = require 'util'
env = require '../config/env'
postageapp = require('postageapp')(env.secrets.postageapp)

Dimension =
  type: Number
  validate: [ (v) ->
    v == null || 0 < v < 6
  , 'out of bounds' ]

ReplySchema = new mongoose.Schema
  personId:
    type: ObjectId
    required: true
  message: String

VoteSchema = module.exports = new mongoose.Schema
  personId:
    type: ObjectId
    required: true
  teamId:
    type: ObjectId
    required: true
  type:
    type: String
    required: true
    enum: Person.ROLES
  comment: String
  utility: Dimension
  design: Dimension
  innovation: Dimension
  completeness: Dimension
  audit:
    remoteAddress: String
    remotePort: Number
    userAgent: String
    referrer: String
    accept: String
    requestAt: Number
    hoverAt: Number
  replies: [ReplySchema]
VoteSchema.plugin require('mongoose-types').useTimestamps

# one vote per person-team-type
VoteSchema.index { personId: 1, teamId: 1, type: 1 }, { unique: true }
VoteSchema.index { personId: 1, updatedAt: -1 }
VoteSchema.index { teamId: 1, updatedAt: -1 }

# class methods
VoteSchema.static 'dimensions',
  [ 'utility', 'design', 'innovation', 'completeness' ]
VoteSchema.static 'label', (dimension) ->
  switch dimension
    when 'utility'      then 'Utility/Fun'
    when 'design'       then 'Design'
    when 'innovation'   then 'Innovation'
    when 'completeness' then 'Completeness'
VoteSchema.static 'Reply', -> Reply

# instance methods
VoteSchema.method 'replyable', (person) ->
  @personId.equals(person.id) or
    @team.includes(person)

VoteSchema.method 'notifyTeam', ->
  @team.people (err, people) =>
    throw err if err

    @person.team (err, voterTeam) =>
      throw err if err

      for person in people
        util.log "Sending 'voted_on_by_#{@type}' to '#{person.email}'".yellow
        postageapp.apiCall person.email, "voted_on_by_#{@type}", null, 'all@nodeknockout.com',
          vote_id: @id
          person_id: @person.id
          person_name: @person.name
          utility_score: @utility
          design_score: @design
          innovation_score: @innovation
          completeness_score: @completeness
          comment: @comment
          team_id: @team.slug
          entry_name: @team.entry.name
          person_team_id: voterTeam?.slug
          person_entry_name: voterTeam?.entry?.name

# associations
VoteSchema.static 'people', (votes, next) ->
  peopleIds = _.pluck votes, 'personId'
  return next() if peopleIds.length == 0
  # TODO only need certain fields probably; make `only` an argument
  Person.find _id: { '$in': peopleIds }, (err, people) ->
    return next err if err
    people = _.reduce people, ((h, p) -> h[p.id] = p; h), {}
    _.each votes, (v) -> v.person = people[v.personId]
    next()
VoteSchema.static 'teams', (votes, next) ->
  teamIds = _.pluck votes, 'teamId'
  return next() if teamIds.length == 0
  # TODO only need certain fields probably; make `only` an argument
  Team = mongoose.model 'Team'
  Team.find _id: { '$in': teamIds }, (err, teams) ->
    return next err if err
    teams = _.reduce teams, ((h, t) -> h[t.id] = t; h), {}
    _.each votes, (v) -> v.team = teams[v.teamId]
    next()

Reply = mongoose.model 'Reply', ReplySchema
Vote = mongoose.model 'Vote', VoteSchema
