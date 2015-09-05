# woot

Core library for creating real time collaborative documents without Operational
transformation (WOOT). This package provides the core logic and data types for building a server capable and handling real time editing with WOOT.

[Reference](https://hal.inria.fr/inria-00071240/document)

Install

```
$ stack install woot
```

Test

```
stack test
```

Notes:

* Haskell server is a passive peer in the process
* only needs a remote integration function

* https://github.com/kroky/woot/blob/master/src/woot.coffee
* https://bitbucket.org/d6y/woot

TODO:

* ci
* docs
* examples

* `WString.subsection` should not have an index error
* Consider ditching `sendLocalOperation` in favor of building ops (easier to tell user if building the operation failed)
