_ = require 'underscore'
qs = require 'querystring'
md = require 'marked'
mongoose = require 'mongoose'

module.exports = (app) ->

  app.helpers

    inspect: require('util').inspect
    qs: qs
    _: _

    markdown: (str) -> if str? then md.parse str, sanitize: true else ''
    markdown_ok: " <a href='http://daringfireball.net/projects/markdown/syntax'>Markdown</a> ok."

    relativeDate: require 'relative-date'

    pluralize: (n, counter) ->
      if n is 1
        "1 #{counter}"
      else
        "#{n} #{counter}s"

    avatar_url: (person, size = 30) ->
      if person.avatarURL
        person.avatarURL size*2
      else
        person.imageURL

    sponsors: require '../models/sponsor'

    locations: (people) ->
      _(people).chain()
        .compact()
        .pluck('location')
        .reduce((r, p) ->
          if p
            k = p.toLowerCase().replace(/\W.*/, '')
            r[k] = p if (!r[k] || r[k].length > p.length)
          r
        , {})
        .values()
        .value().join '; '

    address: (addr, host = 'maps.google.com') ->
      """
      <a href="http://#{host}/maps?q=#{addr}">
        <img class="map" src="http://maps.googleapis.com/maps/api/staticmap?center=#{addr}&zoom=15&size=226x140&sensor=false&markers=size:small|#{addr}"/>
      </a>
      """

    registration: app.enabled 'registration'
    preCoding: app.enabled 'pre-coding'
    coding: app.enabled 'coding'
    voting: app.enabled 'voting'

    Vote: mongoose.model 'Vote'
    stars: (count) ->
      stars = for i in [1..5]
        state = if i <= count then ' filled' else ''
        "<div class='star#{state}'></div>"
      "<div class='stars'>#{stars.join ''}</div>"

  app.dynamicHelpers

    session: (req, res) -> req.session

    req: (req, res) -> req

    _csrf: (req, res) ->
      """<input type="hidden" name="_csrf" value="#{req.session._csrf}"/>"""

    title: (req, res) ->
      (title) ->
        req.pageTitle = title if title
        req.pageTitle

    admin: (req, res) -> req.user?.admin

    flash: (req, res) -> req.flash()

    canEdit: (req, res) ->
      (thing) ->
        if u = req.user
          u.admin or (u.id is thing.id)

    urlFor: (req, res) ->
      (options) ->
        q = _.clone req.query
        delete q._pjax
        _.extend q, options
        req.url.split('?')[0] + '?' + qs.stringify(q)
