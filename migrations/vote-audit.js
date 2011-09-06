db.teams.find({ 'entry.votable': true, lastDeploy: { $ne: null }}).sort({ 'scores.popularity_count': -1 }).limit(10).forEach(function(team) {
  print("\n###" + team.name);
  var i = 0
    , clickDeltas = []
    , responseDeltas = []
    , byHour = {}
    , byIP = {}
    , byUA = {}
    , byReferrer = {}
    , byLocale = {}
    , byGender = {}
    , byVerified = {};
  db.votes.find({ teamId: team._id, type: 'voter' }).sort({ id: 1 }).forEach(function(vote) {
    var clickDelta = (vote.audit.hoverAt - vote.audit.requestAt) / 1000
      , responseDelta = (+vote.updatedAt - vote.audit.requestAt) / 1000
      , person = db.people.findOne({ _id: vote.personId })
      , hour = '' + (vote.updatedAt.getMonth() + 1) + zeroize(vote.updatedAt.getUTCDate()) + zeroize(vote.updatedAt.getUTCHours());
    print([
      hour,
      i++,
      clickDelta.toFixed(1),
      responseDelta.toFixed(1),
      vote.audit.remoteAddress,
      vote.updatedAt
    ].join(" - "));
    if (person) {
      print('  ' + [
        person.fb.name.full,
        person.fb.verified,
        person.fb.email,
        person.fb.gender,
        person.fb.locale,
        'http://facebook.com/' + person.fb.id
      ].join(' - '));
    } else {
      // deleting these votes because they look sketchy
      print("  no person found!");
    }
    // print("  " + vote.audit.userAgent);
    // print("  " + (vote.audit.referrer || 'none'));
    // print("");

    clickDeltas.push(clickDelta);
    responseDeltas.push(responseDelta);
    byHour[hour] = (byHour[hour] || 0) + 1;
    byIP[vote.audit.remoteAddress] = (byIP[vote.audit.remoteAddress] || 0) + 1;
    byUA[vote.audit.userAgent] = (byUA[vote.audit.userAgent] || 0) + 1;
    byReferrer[vote.audit.referrer] = (byReferrer[vote.audit.referrer] || 0) + 1;
    byLocale[person.fb.locale] = (byLocale[person.fb.locale] || 0) + 1;
    byGender[person.fb.gender] = (byGender[person.fb.gender] || 0) + 1;
    byVerified[person.fb.verified] = (byVerified[person.fb.verified] || 0) + 1;
  });

  print('Clicks: ' + quartiles(clickDeltas).join(' '));
  print('Responses: ' + quartiles(responseDeltas).join(' '));
  printjson(byLocale);
  printjson(byGender);
  printjson(byVerified);
  printjson(byReferrer);
  printjson(byHour);
  printjson(byIP);
  printjson(byUA);

  // print('Avg click: ' + (clickDeltaSum / i).toFixed(2));
  // print('Avg response: ' + (responseDeltaSum / i).toFixed(2));
});


function quartiles(arr) {
  var min = 0, max = arr.length - 1
    , q1 = Math.round(arr.length / 4 * 1) - 1
    , q2 = Math.round(arr.length / 4 * 2) - 1
    , q3 = Math.round(arr.length / 4 * 3) - 1;
  function byNum(a, b) { return a - b; }
  arr.sort(byNum);
  return [arr[min], arr[q1], arr[q2], arr[q3], arr[max]];
}

function zeroize(num) {
  return num < 10 ? '0' + num : num;
}
