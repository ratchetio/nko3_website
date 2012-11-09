var teamsWithStats = db.teams.distinct('slug', { stats: { $exists: 1 }})
printjson(teamsWithStats)

db.teams.update({ slug: { $in: teamsWithStats }}, { $unset: { stats: 1 }}, false, true)
