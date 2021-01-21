import os
from random import random, randint

from mlflow import mlflow, log_metric, log_param, log_artifacts

MLFLOW_TRACKING_URI = 'http://0.0.0.0:8989'

if __name__ == "__main__":
    mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

    with mlflow.start_run() as run:
        print("Running mlflow_tracking.py")

        log_param("param1", randint(0, 100))

        log_metric("foo", random())
        log_metric("foo", random() + 1)
        log_metric("foo", random() + 2)

        if not os.path.exists("outputs"):
            os.makedirs("outputs")
        with open("outputs/test.txt", "w") as f:
            f.write("hello world!")

        log_artifacts("outputs")
