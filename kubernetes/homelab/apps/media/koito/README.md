# Koito

Command to add files to import folder:

```sh
for f in ../mediamonkey-to-koito/output/*.json; do kubectl -n media cp "$f" "$(kubectl -n media get pod -l app.kubernetes.io/name=koito -o name | head -1 | cut -d/ -f2)":/etc/koito/import/; done
```
