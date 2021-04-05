const express = require("express");
const app = express();
const jsonServer = require('json-server');
const jsonapp = jsonServer.create();
const minDelay = 30;
const maxDelay = 250;

//collectmetric
const prometheusExporter = require('@tailorbrands/node-exporter-prometheus');
const options = {
  appName: "crocodile-api",
  collectDefaultMetrics: true,
  ignoredRoutes: ['/metrics', '/favicon.ico', '/__rules']
};
const promExporter = prometheusExporter(options);
jsonapp.use(promExporter.middleware);
jsonapp.get('/metrics', promExporter.metrics);

const middlewares = jsonServer.defaults()
jsonapp.use(middlewares);

// Add a delay to /crocodiles requests only
jsonapp.use('/crocodiles', function (req, res, next) {
  let delay = Math.floor(Math.random() * (maxDelay - minDelay)) + minDelay;
  setTimeout(next, delay)
});

const router = jsonServer.router('db.json');
jsonapp.use(router);


app.listen(3000, function () {
  
console.log("listening on 3000");
});

app.get("/", (req, res) => {
  res.send("Users Shown");
console.log("Users Shown");
});

app.get("/delete", (req, res) => {
  res.send("Delete User");
console.log("Delete User");
});

app.get("/update", (req, res) => {
  res.send("Update User");
console.log("Update User");
});

app.get("/insert", (req, res) => {
  res.send("Insert User");
console.log("Insert User");
});

