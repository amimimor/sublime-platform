 <a href="https://sublimesecurity.com"><img src="https://user-images.githubusercontent.com/11003450/115128085-5805da00-9fa9-11eb-8c7a-dc8b708053ee.png" width="75px" alt="Sublime Logo" /></a>

Sublime Platform
==========

by Sublime Security

Overview
---------

A free and open platform for detecting and preventing email attacks like BEC, malware, and credential phishing. Gain visibility and control, hunt for advanced threats, and collaborate with the community.

Sublime uses Message Query Language (MQL), a domain-specific language purpose-built for describing behavior in email. MQL is email provider agnostic, enabling defenders to write, run, and share Detections-as-Code.

Learn more about MQL: [Introduction to Message Query Language](https://sublime.security/blog/introduction-to-message-query-language-mql)

Setup
----------

```console
curl -sL https://raw.githubusercontent.com/sublime-security/sublime-platform/main/install-and-launch.sh | sh
```

[View Docker Quickstart](https://docs.sublimesecurity.com/docs/quickstart-docker)

[View other deployment methods](https://sublime.security/start)

Detection rules
----------

Open-source detection rules and links to community Feeds are maintained in the [sublime-rules repo](https://github.com/sublime-security/sublime-rules).

Testing the Rules Engine
------------------------

This section provides instructions on how to run a simple test to verify that the Sublime rules engine is working correctly in the Kubernetes environment.

### Step 1: Deploy the Rules Engine

First, you need to deploy the application to your Kubernetes cluster using the Helm chart we've prepared.

1. **Open your terminal** and navigate to the `sublime-platform` directory.
2. **Run the following Helm command** to install or upgrade the release named `my-rules-engine`:

    ```bash
    helm upgrade --install my-rules-engine ./sublime-rules-engine --namespace default
    ```

3. **Wait for the deployment to complete.** You can monitor the status of all the pods with this command:

    ```bash
    kubectl get pods --namespace default -w
    ```

    Wait until all pods show `Running` in the `STATUS` column and are ready (e.g., `1/1` in the `READY` column). This might take a few minutes, especially the first time, as the `bora-lite` service waits for `mantis` to run its database migrations.

### Step 2: Run the Test Script

Once all the pods are running, you can run the test script `scan_file.sh`.

1. **Make sure the script is executable:**

    ```bash
    chmod +x scan_file.sh
    ```

2. **Execute the script:**

    ```bash
    ./scan_file.sh
    ```

#### What the Test Script Does

The `scan_file.sh` script automates the process of testing the rule engine. Here's what it does step-by-step:

1. It creates a temporary file named `test.txt` containing the string "hello world".
2. It finds the running `strelka-frontend` pod in your Kubernetes cluster.
3. It uses `kubectl port-forward` to create a secure tunnel from your local machine (port 56564) to the `strelka-frontend` pod's port.
4. It sends the `test.txt` file to the scanning endpoint using `curl`.
5. Finally, it cleans up by stopping the port-forwarding process and deleting the `test.txt` file.

### Step 3: Verify the Results

The script will submit the file for scanning. To see the result and confirm that our `HelloWorld` Yara rule was triggered, you can inspect the logs of the `strelka-backend` pods.

Run the following command to view the logs from both `strelka-backend` replicas:

```bash
kubectl logs -n default -l "app.kubernetes.io/name=sublime-rules-engine-strelka-backend"
```

In the log output, you should see a JSON object that corresponds to the scan event. It will contain details about the file, and most importantly, it should include an entry for the Yara scan, indicating a match for the `HelloWorld` rule. It will look something like this:

```json
{
  "event": {
    "flavor": "yara",
    "yara": [
      {
        "rule": "HelloWorld",
        "tags": [],
        "meta": {},
        "strings": [
          {
            "name": "$a",
            "offset": 0
          }
        ]
      }
    ]
  },
  "file": { ... }
}
```

Seeing the `HelloWorld` rule in the logs confirms that the entire pipeline is working correctly: the file was submitted, routed to a backend worker, and scanned against the custom Yara rule we provided.

Learn more
----------

- [Docs](https://docs.sublimesecurity.com)
- [API](https://docs.sublimesecurity.com/reference/introduction)
- [Release log](https://new.sublimesecurity.com)
- [Message Query Language (MQL)](https://docs.sublimesecurity.com/docs/message-query-language)
