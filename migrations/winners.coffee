require 'colors'
env = require '../config/env'
mongoose = require('../models')(env.mongo_url)

Team = mongoose.model 'Team'

winners =
  solo: 'speedo'
  overall: 'somethingcoded'
  popularity: 'go-horse-brazil'
  utility: 'opower'
  design: 'rochester-js'
  innovation: 'minimason'
  completeness: 'joshfire'

blurb = (category, slug, fn) ->
  Team.findOne slug: slug, (err, team) ->
    console.log team.name
    fn """
      <div style='clear:both'></div>
      <a href='#{team.entry.url}'><img src='#{team.screenshot}' style='float:right;margin-left:1ex;margin-top:10px;'></a>
      <h2 style='margin-bottom:0'>
        #{category}:
        <a href='#{team.entry.url}'>#{team.entry.name}</a>
      </h2><div>by <a href='http://nodeknockout.com/teams/#{team}'>#{team.name}</a></div>

      #{team.entry.description}
      """

blurbs = []
threads = 0
for category, slug of winners
  threads++
  blurb category, slug, (txt) ->
    blurbs.push txt
    unless --threads
      console.log blurbs.join "\n\n"
      mongoose.disconnect()

