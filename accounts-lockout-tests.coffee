if Meteor.isServer
  Tinytest.add 'accounts-lockout defined', (test) ->
    test.ok AccountsLockout


Accounts._noConnectionCloseDelayForTest = true
Accounts._isolateLoginTokenForTest() if Meteor.isClient

#picked from accounts-password package
`
if (Meteor.isServer) {
  Meteor.methods({
    getUserId: function () {
      return this.userId;
    },
    getResetToken: function () {
      var token = Meteor.users.findOne(this.userId).services.password.reset;
      return token;
    }
  });
}

if (Meteor.isClient) {
  var logoutStep = function (test, expect) {
    Meteor.logout(expect(function (error) {
      test.equal(error, undefined);
      test.equal(Meteor.user(), null);
    }));
  };
  var loggedInAs = function (someUsername, test, expect) {
    return expect(function (error) {
      test.equal(error, undefined);
      test.equal(Meteor.user().username, someUsername);
    });
  };
  var waitForLoggedOutStep = function (test, expect) {
    pollUntil(expect, function () {
      return Meteor.userId() === null;
    }, 10 * 1000, 100);
  };
  var invalidateLoginsStep = function (test, expect) {
    Meteor.call("testInvalidateLogins", 'fail', expect(function (error) {
      test.isFalse(error);
    }));
  };
  var hideActualLoginErrorStep = function (test, expect) {
    Meteor.call("testInvalidateLogins", 'hide', expect(function (error) {
      test.isFalse(error);
    }));
  };
  var validateLoginsStep = function (test, expect) {
    Meteor.call("testInvalidateLogins", false, expect(function (error) {
      test.isFalse(error);
    }));
  };
}
`


if Meteor.isClient
  ( ->
    testAsyncMulti "accounts-lockout - lock a user after 5 failed attempts", [
      (test, expect) ->
        # setup
        @username = Random.id()
        @email = Random.id() + '-intercept@example.com'
        @password = 'password';
        Accounts.createUser username: this.username, email: this.email, password: this.password,
          loggedInAs this.username, test, expect


      (test, expect) ->
        test.notEqual(Meteor.userId(), null)


      logoutStep


      (test, expect) ->
        Meteor.loginWithPassword this.username, this.password, loggedInAs this.username, test, expect

        
    ]
  )()




























