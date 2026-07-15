# Hermes

Check deploy state:

```sh
flux get kustomizations -n ai
flux get helmreleases -n ai
kubectl get pods -n ai -l app.kubernetes.io/name=hermes
kubectl get externalsecret,secret -n ai | grep hermes
```

Check Hermes status:

```sh
kubectl -n ai exec deploy/hermes -- hermes status
```

Run one prompt:

```sh
kubectl -n ai exec -it deploy/hermes -- hermes chat --query "say ok"
```

Start interactive chat in the pod:

```sh
kubectl -n ai exec -it deploy/hermes -- hermes chat
```

Start TUI in the pod:

```sh
kubectl -n ai exec -it deploy/hermes -- hermes chat --tui
```

Shell into pod:

```sh
kubectl -n ai exec -it deploy/hermes -- sh
```

Run Hermes inside pod:

```sh
hermes --help
hermes model
hermes
```

Open Gateway route:

```sh
open https://hermes.drmoo.io
```

Note: current service exposes Hermes gateway port `8642`, not web dashboard port `9119`.
Use `kubectl exec -it ... hermes chat --tui` for interactive use unless dashboard is added later.

Debug config and logs:

```sh
kubectl -n ai logs deploy/hermes -f
kubectl -n ai exec deploy/hermes -- sh -c 'ls -la /opt/data && sed -n "1,120p" /opt/data/config.yaml'
kubectl -n ai describe externalsecret hermes-secret
kubectl -n ai describe helmrelease hermes
```
