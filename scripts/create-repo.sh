#!/bin/sh

slug=$1
code=$2
name=$3
github=$4

mkdir -p repos/${slug}
pushd repos/${slug}
git init

cat <<EOF >README.md
# ${name}

## require('nko')

We've generated a \`package.json\` and \`server.js\` for you. Feel free to
change anything you like, but please **preserve the \`require('nko')\` call at
the top of \`server.js\`** for [deploy check-ins][1] to work. You can of course
rename \`server.js\` to anything you like too, but make sure to copy over that
\`require('nko')\` line.


## Deploy instructions

### GitHub — [Team][2], [Repo][3]

~~~sh
git clone git@github.com:nko3/${slug}.git
~~~

### Nodejitsu — [Handbook][4]

~~~sh
npm install -g jitsu
jitsu login --username nko3-${slug} --password ${code}
jitsu deploy
~~~


## Have fun!

If you have any issues, we're on IRC in #nodeknockout and #nodejitsu on
freenode, email us at <all@nodeknockout.com>, or tweet
[@node_knockout](https://twitter.com/node_knockout).

[1]: https://github.com/nko3/website/blob/master/module/README.md
[2]: https://github.com/organizations/nko3/teams/${github}
[3]: https://github.com/nko3/${slug}
[4]: http://handbook.jit.su
EOF

cat <<EOF >package.json
{
  "name": "${slug}",
  "version": "0.0.0",
  "description": "${name}",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "repository": {
    "type": "git",
    "url": "git@github.com:nko3/${slug}.git"
  },
  "dependencies": {
    "nko": "*"
  },
  "engines": {
    "node": "0.8.x"
  }
}
EOF

cat <<EOF >server.js
require('nko')('${code}');  // ! Don't change or remove during competition

var http = require('http');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(8000);

console.log('Server running at http://0.0.0.0:8000/');
EOF

git add .
git commit -m Instructions
git remote add origin git@github.com:nko3/${slug}.git
git push origin master
popd
