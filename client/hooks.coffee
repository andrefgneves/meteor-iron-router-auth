hooks = Iron.Router.hooks

sessionKey = 'iron-router-auth'

hooks.authenticate = ->
  if @route.getName() is '__notfound__' or Meteor.userId()
    @next()
    return

  return if Meteor.loggingIn()

  ns = 'authenticate'

  options = @lookupOption ns

  if options is false
    @next()
    return

  dashboard = options?.dashboard
  layout = options?.layout
  logout = options?.logout
  replaceState = options?.replaceState
  route = options?.route
  template = options?.template

  route = options if _.isString options

  check dashboard, Match.Optional String
  check layout, Match.Optional String
  check logout, Match.Optional String
  check replaceState, Match.Optional Boolean
  check route, Match.Optional String
  check template, Match.Optional String

  replaceState ?= true

  if @route.getName() is logout
    dashboard = '/' unless @router.routes[dashboard] and dashboard
    @redirect dashboard, {}, replaceState: replaceState
    return

  if route and @router.routes[route]
    params = {}
    params[key] = value for own key, value of @params

    sessionValue =
      params: params
      route: @route.getName()

    Session.set sessionKey, sessionValue
    @redirect route, {}, replaceState: replaceState
    return

  @layout = layout if layout
  @render template or new Template -> 'Not authenticated...'
  @renderRegions()

hooks.authorize = ->
  if @route.getName() is '__notfound__'
    @next()
    return

  authenticate = @lookupOption 'authenticate'

  if authenticate is false
    @next()
    return

  return if Meteor.loggingIn() or not Meteor.userId()

  ns = 'authorize'

  options = @lookupOption ns

  if options is false
    @next()
    return

  allow = options?.allow
  deny = options?.deny

  check allow, Match.Optional Function
  check deny, Match.Optional Function

  if not allow? and deny?
    authorized = not deny()

  else if allow? and not deny?
    authorized = allow()

  else if allow? and deny?
    authorized = not deny() and allow()

  if authorized
    @next()
    return

  if Package.insecure
    console.warn 'Remove "insecure" package to respect allow and deny rules.'
    @next()
    return

  layout = options?.layout
  replaceState = options?.replaceState
  route = options?.route
  template = options?.template

  check layout, Match.Optional String
  check replaceState, Match.Optional Boolean
  check route, Match.Optional String
  check template, Match.Optional String

  if route and @router.routes[route]
    params = {}
    params[key] = value for own key, value of @params

    sessionValue =
      notAuthorized: true
      params: params
      route: @route.getName()

    Session.set sessionKey, sessionValue
    replaceState ?= true
    @redirect route, {}, replaceState: replaceState
    return

  @state.set 'iron-router-auth',
    notAuthorized: true

  @layout layout if layout
  @render template or new Template -> 'Access denied...'
  @renderRegions()
  unless template
    console.warn 'No template set for authorize hook.'

hooks.noAuth = ->
  if @route.getName() is '__notfound__' or not Meteor.userId()
    @next()
    return

  return if Meteor.loggingIn()

  sessionValue = Session.get sessionKey

  if Meteor.userId() and sessionValue?.notAuthorized
    @next()
    return

  ns = 'noAuth'

  options = @lookupOption ns

  replaceState = options?.replaceState
  route = options?.route

  route = options if _.isString options

  check replaceState, Match.Optional Boolean
  check route, Match.Optional String

  replaceState ?= true
  route = sessionValue?.route ? route
  route = '/' unless @router.routes[route] and route

  params = sessionValue?.params ? {}

  delete Session.keys[sessionKey]

  @redirect route, params, replaceState: replaceState
