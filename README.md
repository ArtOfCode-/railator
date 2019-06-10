# Railator
National Rail Darwin API translator server

## What & Why?
This is a Node.JS HTTP server that serves as a translator between National Rail's Darwin API and JSON. Darwin is a SOAP XML API,
which is... difficult, to say the least, to work with in JavaScript; this project aims to solve that problem by sitting in between
client applications and Darwin to translate into JSON.

## Install
```
git clone git@github.com:ArtOfCode-/railator
cd railator
cp config.sample.js config.js
```

You'll need to edit the values in `config.js`: pick the port you want the server to run on, and provide a valid access token for LDBSVWS,
which you can obtain [here](http://openldbsv.nationalrail.co.uk/) (for now). Then:

```
npm install
npm start
```