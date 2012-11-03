#!/bin/sh

slug=$1
code=$2
name=$3

mkdir -p repos/${slug}
pushd repos/${slug}
git init

cat <<EOF >README.md
# ${name}

We have generated a \`package.json\` for you with a very important post-deploy
hook for nodejitsu. Feel free to change anything you want in \`package.json\`,
but preserve the post-deploy hook.

Have fun!
EOF

cat <<EOF >package.json
{
  "name": "${slug}",
  "version": "0.0.0",
  "description": "${name}",
  "main": "index.js",
  "scripts": {
  },
  "repository": {
    "type": "git",
    "url": "git@github.com:nko3/${slug}.git"
  },
  "author": "",
  "license": "BSD",
  "readmeFilename": "README.md"
}
EOF

git add .
git commit -m Instructions
git remote add origin git@github.com:nko3/${slug}.git
git push origin master
popd
