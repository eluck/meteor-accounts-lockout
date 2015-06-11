Package.describe({
  name: 'accounts-lockout',
  version: '0.0.1',
  summary: 'Locks user accounts for N seconds after them having entered wrong passwords M times in row',
  git: 'https://github.com/eluck/meteor-accounts-lockout',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use(['accounts-password', 'coffeescript'], 'server');
  api.use('check');
  api.addFiles('accounts-lockout.coffee', 'server');
  api.export('AccountsLockout', 'server');
});

Package.onTest(function(api) {
  api.use(['accounts-base', 'accounts-password', 'tinytest', 'test-helpers', 'tracker',
     'random', 'email', 'underscore', 'check',
    'ddp']);
  api.use(['coffeescript', 'accounts-lockout']);
  api.addFiles('password_tests_setup.js', 'server');
  api.addFiles('accounts-lockout-tests.coffee');
});
