---
title: JVM
date: 2021-01-04 16:37:46
---

## GC tuning

### All allocations, no sampling or bias

```
-XX:+UnlockExperimentalVMOptions 
-XX:+UseEpsilonGC 
-XX:+HeapDumpOnOutOfMemoryError
```

NOTE: with [Eclipse MAT](https://www.eclipse.org/mat/) use the "keep unreachable objects" option.
