derby = require 'derby'
app = derby.createApp module
derby.use(require 'derby-ui-boot')
derby.use(require '../../ui')
uuid = require('node-uuid')
fs = require('fs')
i18n = require("i18n")
#i18n = require('derby-i18n')
#app = i18n.localize app, 
#  availableLocales: ['en']
#  urlScheme: 'path'

#i18n.configure
  #setup some locales - other locales default to en silently
  #locales:['en', 'pt-BR'],
  #where to register __() and __n() to, might be "global" if you know what you are doing
  #register: global
  #debug: true
  #updateFiles: false

#i18n.setLocale('pt-BR')

__ = (v) -> v

get = app.get

pages = [
  {url: '/', title: __('Home')}
  {url: '/offices', title: __('Offices')}
  {url: '/register', title: __('Register')}
]

defaultOffices = [
  {city: "São Carlos", nick: "SC"}
]

render = (name, page) ->
  ctx =
    pages: pages
    activeUrl: page.params.url
  page.render name, ctx

renderEditOffice = (page, model, id) ->
  model.subscribe 'office.' + id, (err, office) ->
    model.ref '_office', office
    render 'editOffice', page

## ROUTES ##

# Derby routes can be rendered on the client and the server
get '/', (page, model) ->
  render 'home', page

get '/register', (page, model) ->
  model.del '_registrationId'
  id = uuid.v4()
  model.set '_registrationId', id
  model.subscribe 'office', 'main.offices', (err, offices) ->
    model.refList '_offices', offices, 'main.offices'
    render 'register', page

get '/offices', (page, model) ->  
  model.subscribe 'office', 'main.offices', (err, offices) ->
    model.refList '_offices', offices, 'main.offices'
    render 'offices', page

get '/offices/:id', (page, model, params) ->
  id = params.id
  model.del '_officeId'
  if id is 'new'
    #model.async.incr 'officesCount', (err, count) ->
    id = uuid.v4();
    model.set '_officeId', id
    renderEditOffice page, model, id
  else
    model.async.get 'main.offices', (err, ids) ->
      if ids?.indexOf(id) > -1
        renderEdit page, model, id
      else
        render 'offices', page
        #app.view.history.push "/offices"

app.view.fn '__', __

app.ready (model) ->
  # unless model.get 'main.offices'
  #     model.push 'main.offices', [
  #       {city: "São Carlos", nick: 'SC'},
  #       {city: "Belo Horizonte", nick: 'Belo Horizonte'}
  #     ]
  #unless model.get 'office'

  history = app.view.history

  checkForm = (path, el) ->
    checkValue = (value) ->
      return unless value
      model.del '_error.' + path
      model.removeListener path, checkValue
    model.on 'set', path, checkValue
    unless model.get(path)
      model.set '_error.' + path, true
      document.getElementById(el).focus()

  app.submitOffice = () ->
    if not model.get('_office.city') or not model.get('_office.nick')
      checkForm('_office.nick', 'nick')
      checkForm('_office.city', 'city')
      return
    newId = model.get('_officeId')
    model.push 'main.offices', newId if newId?
    history.push '/offices'
    model.del '_officeId'

  app.cancel = () ->
    model.del '_officeId'
    history.back()

  app.deleteOffice = () ->
    model.async.get 'main.offices', (err, ids) ->
      if ids
        id = model.get '_office.id'
        i = ids.indexOf id
        model.remove 'main.offices', i if (i > -1) 
      history.back()