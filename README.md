# BruteForceNBody

An 2 dimensional n-body simulation using [verlet integration](https://gereshes.com/2018/07/09/verlet-integration-the-n-body-problem/) to show use of a [pthread_rwlock](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_rwlock_rdlock.3.html) create a pipeline for simulation and rendering so that the next simulation frame can be calculated as the current frame is being rendered.

![image](./preview.gif "Preview")
