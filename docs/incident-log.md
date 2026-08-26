# Incident Log

This is a incident log for every incident for `sanae` that has been encountered.
Below is the table containing all the incidents with the following fields:

- **Incident:** the ID code of the incident (SANAE-XXX), also a link to the full report
- **Affected:** the services affected by the incident
- **Cause:** short desciption of what caused the incident
- **Fix Commit:** the commit hash which fixed the issue

## Incident Table

| Incident | Affected | Cause | Fix Commit |
| :--- | :--- | :--- | :--- |
| [SANAE-001](#sanae-001-misconfigured-cilium-broke-cni-setup) | Cluster | Misconfigured Cilium | 3f53c79 |

## Full Reports

### [SANAE-001]: Misconfigured Cilium Broke CNI Setup

During the initial setup of Cilium, the K3s had accidentally been deployed with `kube-proxy`
enabled, which allowed Cilium to detect the cluster using the `kubernetes` service. After a
reboot, Cilium failed to start up, trying to connect to the same `kubernetes` service, which
no longer was serving traffic to anything.

The fix was to tell Cilium what the host IP and port were. This was done by appending the
following lines to the Cilium's values:

```yaml
k8sServiceHost: "{{ ansible_facts['default_ipv4']['address'] }}"
k8sServicePort: "6443"
```
