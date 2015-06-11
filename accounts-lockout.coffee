AccountsLockout =
  settings:
    duration: 15
    attempts: 5



  startup: ->
    AccountsLockout.updateSettingsIfSpecified()
    AccountsLockout.scheduleUnlocksForLockedAccounts()
    AccountsLockout.unlockAccountsIfLockoutAlreadyExpired()
    AccountsLockout.hookIntoAccounts()



  updateSettingsIfSpecified: ->
    if Meteor.settings["accounts-lockout"]
      AccountsLockout.settings[key] = value for key, value of Meteor.settings["accounts-lockout"]
    check AccountsLockout.settings.duration, Match.Integer
    check AccountsLockout.settings.attempts, Match.Integer
    if AccountsLockout.settings.duration < 0
      throw 'eluck:accounts-lockout package - "duration" is not positive integer'
    if AccountsLockout.settings.attempts < 0
      throw 'eluck:accounts-lockout package - "attempts" is not positive integer'



  scheduleUnlocksForLockedAccounts: ->
    currentTime = Number new Date()
    lockedAccountsCursor = Meteor.users.find 'services.accounts-lockout.unlockTime': $gt: currentTime,
      fields: 'services.accounts-lockout.unlockTime': 1
    currentTime = Number new Date() #db query can take some time, let's take it into account
    lockedAccountsCursor.forEach (user) ->
      lockDuration = user.services['accounts-lockout'].unlockTime - currentTime
      lockDuration = if lockDuration < AccountsLockout.settings.duration then lockDuration
      else AccountsLockout.settings.duration
      lockDuration = if lockDuration > 1 then lockDuration else 1
      Meteor.setTimeout AccountsLockout.unlockAccount.bind(null, user._id), lockDuration



  unlockAccount: (userId) ->
    Meteor.users.update userId,
      $unset: 'services.accounts-lockout.unlockTime': 0, 'services.accounts-lockout.failedAttempts': 0



  unlockAccountsIfLockoutAlreadyExpired: ->
    currentTime = Number new Date()
    Meteor.users.update 'services.accounts-lockout.unlockTime': $lt: currentTime,
      $unset: 'services.accounts-lockout.unlockTime': 0, 'services.accounts-lockout.failedAttempts': 0



  hookIntoAccounts: ->
    Accounts.validateLoginAttempt AccountsLockout.validateLoginAttempt
    Accounts.onLogin AccountsLockout.onLogin
    Accounts.onLoginFailure AccountsLockout.onLoginFailure



  validateLoginAttempt: (loginInfo) ->
    return loginInfo.allowed unless loginInfo.type == 'password' #don't interrupt non-password logins
    return loginInfo.allowed unless loginInfo.user
    currentTime = Number new Date()
    if loginInfo.user.services?['accounts-lockout']?.unlockTime <= currentTime
      AccountsLockout.unlockAccount(loginInfo.user._id)
      return loginInfo.allowed
    if loginInfo.user.services?['accounts-lockout']?.unlockTime > currentTime
      duration = loginInfo.user.services['accounts-lockout'].unlockTime - currentTime
      duration = Math.ceil duration / 1000
      duration = if duration > 1 then duration else 1 #just in case
      throw new Meteor.Error AccountsLockout.errorCode,
        JSON.stringify message: AccountsLockout.accountLockedMessage, duration: duration
    return loginInfo.allowed



  #these constants should stay the same across future versions for compatibility
  accountLockedMessage: 'Wrong passwords were submitted too many times. Account is locked for a while.'
  errorCode: 423



  onLogin: (loginInfo) ->
    return unless loginInfo.type == 'password'
    Meteor.users.update loginInfo.user._id,
      $unset: 'services.accounts-lockout.unlockTime': 0, 'services.accounts-lockout.failedAttempts': 0



  onLoginFailure: (loginInfo) ->
    return unless loginInfo.error?.reason == 'Incorrect password'
    return unless loginInfo.user
    return if loginInfo.user.services?['accounts-lockout']?.unlockTime
    failedAttempts = 1 + ensurePositiveNumber loginInfo.user.services?['accounts-lockout']?.failedAttempts
    lastFailedAttempt = ensurePositiveNumber loginInfo.user.services?['accounts-lockout']?.lastFailedAttempt
    currentTime = Number new Date()
    #reset failedAttempts counter if the last fail was too long time ago
    failedAttempts = if currentTime - lastFailedAttempt > 1000 * AccountsLockout.settings.duration then 1
    else failedAttempts
    if failedAttempts < AccountsLockout.settings.attempts
      return Meteor.users.update loginInfo.user._id, $set:
        'services.accounts-lockout.failedAttempts': failedAttempts
        'services.accounts-lockout.lastFailedAttempt': currentTime
    unlockTime = 1000 * AccountsLockout.settings.duration + currentTime
    Meteor.users.update loginInfo.user._id, $set:
      'services.accounts-lockout.unlockTime': unlockTime
      'services.accounts-lockout.failedAttempts': failedAttempts
      'services.accounts-lockout.lastFailedAttempt': currentTime
    Meteor.setTimeout AccountsLockout.unlockAccount.bind(null, loginInfo.user._id),
      1000 * AccountsLockout.settings.duration



Meteor.startup AccountsLockout.startup



ensurePositiveNumber = (num) -> Math.abs(Number(num) || 0)
