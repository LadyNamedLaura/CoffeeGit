
express = require 'express'
ect     = require 'ect'
git     = require 'gift'

app     = express()
app.engine 'ect', ect(watch: on, root : __dirname + '/views').render


app.param 'repo', (req, res, next, id) ->
  req.repo = git __dirname
  next()

app.get '/', (req, res) ->
  res.render 'login.ect', title:'log in'

app.get '/repos/:repo', (req, res) ->
  console.log req.repo
  console.log req.repo.tree()
  req.repo.tree().contents (err, children) ->
    res.render 'repo.ect', repo: req.params.repo, list: children
#    for child in children
#        console.log child.name
#  res.render 'repo.ect', repo: req.params.repo

app.post '/login', (req, res) ->
  user = req.body.user
  if user.name is 'luke' and user.password is 'skywalker'
    res.render 'loggedin', title: "Logged in as #{user.name}", user: user
  else
    res.render 'login', title:'Error', error:true


app.post '/logout', (req, res) ->
  res.render 'login', title:'logged out', loggedOut:true

###
run server
###
port = process.env.PORT or 9294
app.listen port, -> console.log "Server is starting on port: #{port}"
