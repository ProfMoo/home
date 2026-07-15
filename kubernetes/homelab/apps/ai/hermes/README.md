# Hermes

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

Open dashboard route:

```sh
open https://hermes.drmoo.io
```

Dashboard is exposed on `https://hermes.drmoo.io` through Envoy internal.
Gateway API remains exposed on service port `8642` as `agent`.
