# ElasticSense

- Elastic Scheduling for Distributed Learning in Kubernetes: Enhancing Resource Utilization and Efficiency with Non Intrusive Scheduler for DL Workloads.

### Setting Cloud Infra Envronments

1. [/keyfiles/{GOOGLE_SERVICE_ACCOUNT_KEY_FILE}.json](https://cloud.google.com/iam/docs/best-practices-for-managing-service-account-keys)

    ```bash
    export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/keyfiles/{GOOGLE_SERVICE_ACCOUNT_KEY_FILE}.json
    ```

2. [/keyfiles/.ssh/google_compute_engine, /keyfiles/.ssh/google_compute_engine.pub](https://cloud.google.com/compute/docs/connect/create-ssh-keys?hl=ko)


3. /keyfiles/username

    set google ssh/OS login username

4. Run Terraform code.

```bash
    cd Infra-k8s-cluster-without-gpu
    terraform plan
    terraform apply -auto-approve 2>&1 | tee terraform-apply.log
```
---

### Setting Local Infra Environments

1. Setting Local-path-provisioner

https://github.com/rancher/local-path-provisioner

2. [Setting Prometheus](https://hackmd.io/@OrALpDtKSY6QetSsHgj-IA/BJXuuNmYP)

```bash
    
```

    Prometheus: http://<nodeIP>:30000/graph
    AlertManager: http://<nodeIP>:32000/graph
    Grafana: http://<nodeIP>:32000/graph

    User: admin
    Pass: prom-operator


