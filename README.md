# ConstraintRunner

[![Swift Package Manager Compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![MIT Lience](https://img.shields.io/github/license/Drusy/ConstraintRunner)](https://github.com/Drusy/ConstraintRunner/blob/master/LICENSE)

### About

ConstraintRunner is a Swift library allowing you to perform async operations once in a while. A task (an asynchronous operation can be constrained by time or by a precise network conditon. 

API inspired by https://github.com/luoxiu/Schedule

### How to use

Some basic usage, here `someAsyncJob` will be executed at most once a day when the network is reachable. If the task fails, it will be allowed to retry every 10 seconds.

```swift
import ConstraintRunner

let runner = ConstraintRunner(identifier: "runner-id")
    .period(.onceADay)
    .connectivity(atLeast: .reachable)
    .maxRetryInterval(10_000)
 
// didRun indicates if your job have been started or not
let didRun = runner.runIfNeeded { handler in
    someAsyncJob { error in
        // True if the task succeeded
        // False if it failed
        handler(error == nil)
    }
}
```

Synchronous job

```swift
let didRun = runner.runIfNeeded {
    return someSyncJob()
}
```

Force job execution

```swift
runner.runIfNeeded(force: true) { ... }
```

Utility methods

```swift
runner.shouldRun()
runner.didLastExecutionFail()
```
