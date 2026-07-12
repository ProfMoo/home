# LiteLLM

Some small commands to verify it's working. Find master key in Bitwarden.

```sh
# export key (quotes important to ensure bash escaping doesn't happen
export LITELLM_MASTER_KEY='<key>'
```

List models:

```sh
curl https://litellm.drmoo.io/v1/models \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

Test chat:

```sh
curl https://litellm.drmoo.io/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-5.5","messages":[{"role":"user","content":"say ok"}]}'
```

Test Gateway route:

```sh
curl https://litellm.drmoo.io/v1/models \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY"
```

Debug failures:

```sh
kubectl -n ai logs deploy/litellm
kubectl -n ai describe externalsecret litellm-secret
kubectl -n ai describe helmrelease litellm
```
