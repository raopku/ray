# Ray

[![Build Status](https://travis-ci.org/ray-project/ray.svg?branch=master)](https://travis-ci.org/ray-project/ray)

Ray is an experimental distributed execution engine. It is under development and
not ready to be used.

The goal of Ray is to make it easy to write machine learning applications that
run on a cluster while providing the development and debugging experience of
working on a single machine.

Before jumping into the details, here's a simple Python example for doing a
Monte Carlo estimation of pi (using multiple cores or potentially multiple
machines).

```python
import ray
import numpy as np

# Start Ray with some workers.
ray.init(num_workers=10)

# Define a remote function for estimating pi.
@ray.remote
def estimate_pi(n):
  x = np.random.uniform(size=n)
  y = np.random.uniform(size=n)
  return 4 * np.mean(x ** 2 + y ** 2 < 1)

# Launch 10 tasks, each of which estimates pi.
result_ids = []
for _ in range(10):
  result_ids.append(estimate_pi.remote(100))

# Fetch the results of the tasks and print their average.
estimate = np.mean(ray.get(result_ids))
print("Pi is approximately {}.".format(estimate))
```

Within the for loop, each call to `estimate_pi.remote(100)` sends a message to
the scheduler asking it to schedule the task of running `estimate_pi` with the
argument `100`. This call returns right away without waiting for the actual
estimation of pi to take place. Instead of returning a float, it returns an
**object ID**, which represents the eventual output of the computation (this is
a similar to a Future).

The call to `ray.get(result_id)` takes an object ID and returns the actual
estimate of pi (waiting until the computation has finished if necessary).

## Next Steps

- Installation on [Ubuntu](doc/install-on-ubuntu.md), [Mac OS X](doc/install-on-macosx.md)
  - [Troubleshooting](doc/installation-troubleshooting.md)
- [Tutorial](doc/tutorial.md)
- Documentation
  - [Serialization in the Object Store](doc/serialization.md)
  - [Environment Variables](doc/environment-variables.md)
  - [Using Ray with TensorFlow](doc/using-ray-with-tensorflow.md)
  - [Using Ray on a Cluster](doc/using-ray-on-a-cluster.md)
    - [Example Management Using Parallel-SSH](doc/using-ray-on-a-large-cluster.md)

## Example Applications

- [Hyperparameter Optimization](examples/hyperopt/README.md)
- [Batch L-BFGS](examples/lbfgs/README.md)
- [Learning to Play Pong](examples/rl_pong/README.md)
