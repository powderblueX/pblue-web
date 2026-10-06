# Kubernetes through PBlue Lab

The manifests in `infra/k8s` run the same immutable image used by Docker. They are intentionally plain YAML: enough to express normal workload ownership and networking, without Helm, Kustomize, an operator, or a service mesh.

## From source to a reachable workload

```text
Nuxt source + Markdown
        ↓ build
Docker Image
        ↓ run
Container
        ↓ grouped and scheduled by
Pod
        ↓ reconciled by
Deployment
        ↓ selected by
Service
        ↓ optionally exposed by
Ingress
```

### Image and container

`docker build` creates the immutable `pblue-web:0.1.0` image. Kubernetes nodes need to pull that image from a registry (or have it loaded locally in a learning cluster). A container is a running process created from it.

### Pod

A Pod is Kubernetes' smallest scheduling unit. The Deployment's Pod template runs one `web` container and declares port `80`. If a future sidecar genuinely needs the same network and lifecycle, it could share the Pod; the current site does not need one.

### Deployment

`infra/k8s/deployment.yaml` declares two replicas. The Deployment owns a ReplicaSet, which keeps two matching Pods present and replaces them when they disappear. Updating the image changes the Pod template and produces a rolling replacement rather than editing running containers.

Resource requests help the scheduler place Pods. Limits bound runaway consumption. The values are intentionally modest for static Nginx and should be adjusted from observed use rather than guessed upward.

### Probes

- The readiness probe calls `/readyz`. A failing Pod stays running but is removed from Service endpoints, so it stops receiving normal traffic.
- The liveness probe calls `/healthz`. Repeated failure tells the kubelet to restart the container.

Readiness starts quickly because static files require no warm-up. Liveness waits longer to avoid restarting a container during normal startup.

### Service

Pod addresses change as Pods are replaced. `infra/k8s/service.yaml` selects Pods by `app.kubernetes.io/name: pblue-web` and gives them one stable ClusterIP and DNS name. `targetPort: http` refers to the named container port, so the relationship stays readable.

### Ingress

An Ingress is deliberately absent. It only becomes meaningful after the target cluster has an Ingress controller and a decided external routing model. The current production path uses Docker plus Cloudflare Tunnel; inventing an Ingress host would not make that deployment more correct.

### ConfigMap

A ConfigMap supplies non-sensitive runtime configuration. This image has none: public metadata is compiled into the static artifact and Nginx configuration is part of the image. Add a ConfigMap only when a deployment-specific, non-secret value must change without rebuilding.

## Try the manifests

After making the image available to the cluster:

```bash
kubectl apply -f infra/k8s/deployment.yaml
kubectl apply -f infra/k8s/service.yaml
kubectl get deployments,pods,services
kubectl describe deployment pblue-web
kubectl logs deployment/pblue-web
kubectl port-forward service/pblue-web 8037:80
```

With port-forward running, open `http://127.0.0.1:8037`. Delete one Pod and watch the Deployment restore the desired replica count:

```bash
kubectl get pods -l app.kubernetes.io/name=pblue-web
kubectl delete pod <pod-name>
kubectl get pods -l app.kubernetes.io/name=pblue-web --watch
```

This is the central reconciliation experiment: you change observed state, and the controller moves it back toward declared state.
