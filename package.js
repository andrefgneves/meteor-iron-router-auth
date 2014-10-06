Package.describe({
  git: 'https://github.com/zimme/meteor-iron-router-auth.git',
  name: 'zimme:iron-router-auth',
  version: '1.0.1'
  summary: 'Auth plugin and hooks for iron:router',
});

Package.onUse(function (api) {
  api.versionsFrom('0.9.3');

  api.use('accounts-base', 'client');

  api.use([
    'coffeescript',
    'underscore'
  ], ['client', 'server']);

  api.use('iron:router@1.0.0-pre3', ['client', 'server']);

  api.addFiles([
    'client/hooks.coffee',
    'client/plugins.coffee'
  ], 'client');

  api.addFiles([
    'server/hooks.coffee',
    'server/plugins.coffee'
  ], 'server');
});
