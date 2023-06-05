# Creating of new Helm Chart

**More commands**: https://helm.sh/docs/helm/

1. Run the following command replacing the name flag:

```shell
helm create <chart_name>
```
2. Go to the directory that was created and run the following command:

```shell
rm -rf templates/*
```

3. Modify and add manifests that you need and run the following command to validate if this one is correct:

```shell
helm lint .
```

## Test the chart

1. Use Helm CLI to install and thest the chart:

```shell
# Test the installation of the chart
helm install --dry-run <release> <chart_name>
# Install the chart
helm install <release> <chart_name>
helm install <release> <chart_name> --values <chart_location>
# List the charts installed
helm list
# Update the chart
helm upgrade <release> <chart_name>
# Update the chart
helm uninstall <release>
```

# Adding to the App-of-Apps example application

1. Go to the examples/templates folder and create a new YAML file like this:


```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: <chart name>
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: examples
    server: https://kubernetes.default.svc
  project: default
  source:
    path: modules/eks-blueprints-addons/helm/charts/<chart name>
    repoURL: git@github.com:lytxinc/devops-pipeline-infra.git
    targetRevision: add-blueprints
```






