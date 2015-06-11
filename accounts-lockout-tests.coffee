if Meteor.isServer
  Tinytest.add 'AccountsLockout is defined on server', (test) ->
    test.ok AccountsLockout


if Meteor.isClient
  Tinytest.add 'AccountsLockout is not defined on client', (test) ->
    test.throws -> AccountsLockout


Accounts._noConnectionCloseDelayForTest = true
Accounts._isolateLoginTokenForTest() if Meteor.isClient

#picked from accounts-password package as is
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
        Accounts.createUser username: @username, email: @email, password: @password,
          loggedInAs @username, test, expect


      (test, expect) ->
        test.notEqual(Meteor.userId(), null)


      logoutStep


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.call 'isAccountLocked', @username, expect (error, result) ->
          test.equal result, true

    ]



    testAsyncMulti "accounts-lockout - automatically unlock user after timeout", [
      (test, expect) ->
        # setup
        @username = Random.id()
        @email = Random.id() + '-intercept@example.com'
        @password = 'password';
        Accounts.createUser username: @username, email: @email, password: @password,
          loggedInAs @username, test, expect


      (test, expect) ->
        test.notEqual(Meteor.userId(), null)


      logoutStep


      (test, expect) ->
        Meteor.call 'makeAccountAlmostLocked', @username, expect (error, result) ->
          test.equal result, true


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.loginWithPassword @username, 'wrongPassword', expect (error) ->
          test.ok error


      (test, expect) ->
        Meteor.call 'returnAfterLockTimeout', expect (error, result) ->
          test.equal result, true


      (test, expect) ->
        Meteor.loginWithPassword @username, @password,
          loggedInAs @username, test, expect

    ]

  )()
