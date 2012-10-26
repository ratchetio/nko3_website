db.people.find({ email: { $nin: [ /@fortnightlabs\.com$/, /\.nodeknockout.com$/] }}).forEach(function(doc) {
  db.people.update({ _id: doc._id }, { $set: { email: doc.email + '.nodeknockout.com' }});
});
