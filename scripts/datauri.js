#!/usr/bin/env/node

var request = require('request');

request(process.argv[2], {encoding: null}, function(err, res, body) {
  if (err) throw err;
  mime = res.headers['content-type'].split(';')[0];
  console.log('data:' + mime + ';base64,' + body.toString('base64'));
});
