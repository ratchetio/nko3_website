// # people without roles ---> voters
print("\n---\n# people without roles ---> voters");

var peopleWithoutRoles = db.people.distinct('_id', { role: null })
print("" + peopleWithoutRoles.length + " people without roles");

db.people.update({ _id: { $in: peopleWithoutRoles }}, { $set: { role: 'voter' }}, false, true)
printjson(db.people.find({ _id: { $in: peopleWithoutRoles }}, { role: 1 }).toArray());

// # contestants without teams ---> voters
print("\n---\n# contestants without teams ---> voters");

var peopleOnTeams = db.teams.distinct('peopleIds');
// print("" + peopleOnTeams.length + " people on teams");

var contestantsNotOnTeams = db.people.distinct('_id', {
  role: 'contestant',
  _id: { $nin: peopleOnTeams }})
print("" + contestantsNotOnTeams.length + " contestants not on teams");

db.people.update({ _id: { $in: contestantsNotOnTeams }}, { $set: { role: 'voter' }}, false, true)
printjson(db.people.find({ _id: { $in: contestantsNotOnTeams }}, { role: 1 }).toArray());
