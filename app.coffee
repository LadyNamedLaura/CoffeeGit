DATADIR = "data"

express = require 'express'
ect     = require 'ect'
git     = require 'gift'
hljs    = require 'highlight.js'
fs      = require 'fs'

app     = express()
app.engine 'ect', ect(watch: on, root : __dirname + '/views').render

istree = (thing) ->
  return !(thing.find is undefined)

app.param 'repo', (req, res, next, id) ->
  req.repo = git "data/#{req.params.user}/#{id}"
  next()

app.param 'treeish', (req, res, next, id) ->
  req.tree = req.repo.tree(id)
  next()

app.param 'path', (req, res, next, id) ->
  if id.length is 0
    req.object = req.tree
    req.istree = yes
    next()
  else
    if id.substr(-1) == "/"
      id = id.substring 0, id.length - 1
    req.params.path = id
    req.tree.find id, (err, thing) ->
      req.object = thing
      req.istree = istree thing
      next()

app.get '/', (req, res) ->
  fs.readdir DATADIR, (err, files) ->
    res.render 'users.ect', users: files

app.get '/:user', (req, res) ->
  fs.readdir DATADIR+"/"+req.params.user, (err, files) ->
    res.render 'repos.ect', user: req.params.user, repos: files
  
app.get '/:user/:repo', (req, res) ->
  res.redirect "/#{req.params.user}/#{req.params.repo}/master/"

app.get '/:user/:repo/:treeish/:path(*)', (req, res) ->
  if req.istree
    req.object.contents (err, children) ->
      list = []
      for child in children
        list.push({name: child.name, dir: istree(child)})
      res.render 'repo.ect', repo: req.params.repo, fname: req.params.path, list: list
  else
    data = ""
    [dataStream, _] = req.object.dataStream()
    dataStream.on 'data', (buf) ->
      data += buf.toString()
    .on 'end', ->
      data = hljs.highlightAuto(data)
      res.render 'file.ect', repo: req.params.repo, fname: req.params.path, data: data.value

port = process.env.PORT or 9294
app.listen port, -> console.log "Server is starting on port: #{port}"
