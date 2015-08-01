Fibers = Npm.require 'fibers'


wait = (duration) ->
  fiber = Fibers.current
  Meteor.setTimeout (-> fiber.run()), duration
  Fibers.yield()



AccountsLockout.settings.duration = 2



Meteor.methods
  isAccountLocked: (username) ->
    user = Meteor.users.findOne username: username
    throw new Meteor.Error 'isAccountLocked - user not found' unless user
    Boolean user.services?['accounts-lockout']?.unlockTime


  makeAccountAlmostLocked: (username) ->
    user = Meteor.users.findOne username: username
    throw new Meteor.Error 'makeAccountAlmostLocked - user not found' unless user
    currentTime = Number new Date()
    Meteor.users.update user._id, $set:
      'services.accounts-lockout.failedAttempts': AccountsLockout.settings.attempts - 1
      'services.accounts-lockout.lastFailedAttempt': currentTime
    return true


  returnAfterLockTimeout: ->
    wait 1000 * AccountsLockout.settings.duration
    return true

