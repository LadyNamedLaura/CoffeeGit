
express = require 'express'
ect     = require 'ect'
git     = require 'gift'
hljs    = require 'highlight.js'

app     = express()
app.engine 'ect', ect(watch: on, root : __dirname + '/views').render

istree = (thing) ->
  if thing.find is undefined
    return no
  return yes

app.param 'repo', (req, res, next, id) ->
  req.repo = git __dirname
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
    req.tree.find id, (err, thing) ->
      req.object = thing
      req.istree = istree thing
      next()

app.get '/', (req, res) ->
  res.render 'login.ect', title:'log in'

app.get '/repos/:repo', (req, res) ->
  res.redirect "/repos/#{req.params.repo}/master/"

app.get '/repos/:repo/:treeish/:path(*)', (req, res) ->
  if req.istree
    req.object.contents (err, children) ->
      res.render 'repo.ect', repo: req.params.repo, list: children
  else
    data = ""
    [dataStream, _] = req.object.dataStream()
    dataStream.on 'data', (buf) ->
      data += buf.toString()
    .on 'end', ->
      data = hljs.highlightAuto(data)
      console.log data
      res.render 'file.ect', repo: req.params.repo, fname: req.params.path, data: data.value

###
run server
###
port = process.env.PORT or 9294
app.listen port, -> console.log "Server is starting on port: #{port}"
