db.people.find({ email: { $nin: [
      /^visnupx?@gmail.com$/,
      'gerads@gmail.com',
      /@fortnightlabs\.com$/,
      /\.nodeknockout.com$/] }}).forEach(function(doc) {
  db.people.update({ _id: doc._id },
    { $set: { email: doc.email + '.nodeknockout.com' }});
});
