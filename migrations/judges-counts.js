var judges = db.people.find({ role: 'judge', email: /@/, twitterScreenName: /\w/ }).map(function(judge) {
  judge.voteCount = db.votes.count({ personId: judge._id });
  return judge;
});

judges.sort(function(a,b) { return a.voteCount - b.voteCount; }).forEach(function(judge) {
  print([judge.voteCount, judge.name, judge.email, judge._id]);
});
