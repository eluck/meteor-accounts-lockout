## Accounts-lockout package

### Use

Locks user accounts for `duration` seconds after them having entered wrong passwords `attempts` times in a row.
`duration` = 15 and `attempts` = 5 by default and can be overriden in settings file:

``` json
"accounts-lockout" : {
  "duration": 5,
  "attempts": 10
}
```

The package is designed to live in multiple servers environment and survive servers restarts.


### Install

``` bash
meteor add eluck:accounts-lockout
```


### Github repository

[https://github.com/eluck/meteor-accounts-lockout](https://github.com/eluck/meteor-accounts-lockout)
