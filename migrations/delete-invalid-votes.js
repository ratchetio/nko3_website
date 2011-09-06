var validVoters =
  db.people.distinct('_id', { role: 'voter', 'fb.verified' : true  });

db.votes.remove(
  { type: 'voter'
  , personId: { $nin:  validVoters }});
