# Hermes

Check status:

```sh
curl https://hermes.drmoo.io/api/status
```

Inspect API endpoints:

```sh
curl http://localhost:8642/openapi.json
```

Open Gateway route:

```sh
open https://hermes.drmoo.io
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
