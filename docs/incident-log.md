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
| [SANAE-002](#sanae-002-etcd-on-a-hdd) | All | Etcd on a HDD | nil |

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

### [SANAE-002]: Etcd on a HDD

As expected, `etcd` doesn't work that well on a HDD. The initial issue appeared as a 503
HTTP error from the Kubernetes API server. So, no `kubectl` command was able to be processed
by the API server. The symptom also gets worse if a node is pulling a image.

Taking look at the numbers, we can see the IO pressure was the following:

```bash
# avg<seconds>=<cpu-tasks-blocked-by-waiting-for-io>
some avg10=46.2%, avg60=39.4%, avg300=38.4% 
full avg10=42.3%, avg60=36.3%, avg300=35.4%
```

These numbers were taken after the image pulling, meaning they were higher than the above
numbers. However, it's still a problem, as more than a third of operations are waiting on
an answer from the HDD. Digging deeper with `iostat` we find that fsync operations that
`etcd` depends on, take about 103-227ms. As the recommended range for `etcd` is <=10ms
this is pretty horrible.

However, when we check `pidstat`, we make one interesting discovery:

```bash
Average:      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
Average:        0       338      0.00      3.86      0.00       0  jbd2/dm-0-8
Average:        0       387      0.00     91.61      0.00       0  systemd-journal
Average:        0     68119      0.00      1.86      1.86       0  containerd-shim
Average:        0    121713      0.00     38.08      0.00       0  k3s-server
Average:        0    121736      0.00      0.93      0.00       0  containerd
```

The most IO heavy application running is instead `systemd-journal`. This is because
K3s generates a bunch of "took too long" logs for `etcd` operations, which itself
creates a feedback loop which makes it even worse.

#### Baseline (before fix)

Captured on 2026-10-14 from an idle cluster (no synthetic workload):

- **Host:** `sanae` - Debian 13 (trixie), kernel 6.12.101, Intel i5-8300H, 7.5 GiB RAM
- **Disk:** 1 TB 5400 RPM HDD (`sda`, rotational), root LVM on `dm-0`
- **K3s:** v1.36.3+k3s1, single node, 16 pods

| Metric | Before |
| :--- | :--- |
| IO PSI `full avg10` | 36.48% |
| IO PSI `some avg10` | 37.90% |
| `iostat` `%iowait` | 39.5% |
| `dm-0` `%util` | 100% |
| `sda` fsync `f_await` | 13.6 ms |
| etcd raft agreement | 0.64-2.72 s |
| etcd request `time spent` | ~0.97 s |
| `kubectl get nodes` | 99-711 ms |
| K3s "took too long" lines | 26,642 in ~3.5 h (~127/min) |
| journald disk usage | 4.0 GiB |
| etcd db size | 553 MiB |

Method:

```bash
cat /proc/pressure/io
iostat -x 1 3
pidstat -d 1 3
journalctl -u k3s --since '7 days ago' --grep 'took too long' | wc -l
journalctl --disk-usage
du -sh /var/lib/rancher/k3s/server/db/etcd
```

Notes:

- The peak numbers quoted above (PSI `full avg10` 42.3%, fsync 103-227ms) were sampled
  during image pulls. These idle numbers show the pressure is persistent, not just
  load-induced.
- The `etcd` trace localises the slowdown to `agreement among raft nodes before linearized
  reading`, i.e. the WAL fsync path, not the in-memory read path.
- The newest snapshot is dated 2026-09-01 because the host was powered off from
  2026-09-01 to 2026-10-14.

**Exit criterion:** IO PSI `full avg10` below 5% and no `etcd` request timeouts under the
same idle workload.

#### After (post-fix)

_TBD - captured after the tmpfs etcd migration._
