# minimal kubernetes mutating webhook example

## introduction
This was a quick exploration of the base primitives that make mutating webhooks in kubernetes function. Assumes a linux host but probably works in other environments with some coaxing.

### instructions
1. Run `./start-cluster.sh` to create a cluster and tls material for control-plane <-> webhook communication.
2. Install the mutating webhook configuration, deployment and service.
   ```
   export CA_BUNDLE=$(cat webhook/pki/ca.crt | base64 | tr -d '\n')
   kubectl kustomize . | envsubst | k apply -f -
   ```
3. Apply a manifest that satisfies the mutating webhook configuration:
   ```
   kubectl apply -f pod.yml
   ```
4. View that the manifest was modified:
   ```
   kubectl get pods -n test --show-labels
5. View the request the control plane sends to the webhook:
   ```
   kubectl logs deployment/labelmutation
   ```
5. You can modify the webhook behavior by editing `webhook/main.go` and re-running step #2.

