Package.describe({
  name: 'accounts-lockout',
  version: '0.0.1',
  summary: 'Locks user accounts for N seconds after entering wrong password M times in row',
  git: 'https://github.com/eluck/meteor-accounts-lockout',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use('accounts-password', 'server');
  api.use('coffeescript', 'server');
  api.addFiles('accounts-lockout.coffee', 'server');
  api.export('AccountsLockout', 'server');
});

Package.onTest(function(api) {
  api.use('tinytest', 'server');
  api.use('accounts-password', 'server');
  api.use('accounts-lockout', 'server');
  api.addFiles('accounts-lockout-tests.js', 'server');
});
