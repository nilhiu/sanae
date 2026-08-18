# sanae

Welcome! `sanae` is the hostname of my homelab (and a straight reference to [Kochiya Sanae](https://en.touhouwiki.net/index.php?title=Sanae_Kochiya)).
Its goal is to solve an optimist's dream of an internal developer platform (IDP).
As of now, it is designed for a very IOPS-limited device. To be exact, a laptop
with the following specs:

- **CPU:** Intel Core i5-8300H
- **RAM:** 8 GB DDR4
- **Storage:** 1 TB HDD (5400 RPM)

These resource limitations brings its own challenges of choosing the correct
software and configuring them correctly to work as efficiently as it can.

## What It Is for Now

For now it's a simple Ansible playbook that optimizes the system and installs
a K3s cluster for a Debian 13 environment.

## How To Run It

First, set up SSH on your host and get your control node (where you'll be
running Ansible) ready to use that SSH connection (`eval $(ssh-agent -s) && ssh-add <YOUR_SSH_KEY>`).
Now place your host in `ansible/inventory.ini` (replacing `sanae.local` and the `ansible_user` variable), and run:

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook site.yml
```
