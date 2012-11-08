// useful for testing voting
db.teams.update({}, {
  $set: {
    lastDeploy: { hostname: 'example.com', createdAt: new Date },
    entry: { url: 'http://example.com', votable: true, name: 'example' }
  }
}, false, true)
