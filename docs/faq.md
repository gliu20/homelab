# FAQ

Q: Where are build artifacts written?
A: ./build — per-service under build/services/<name>/<name>.ign and the main host at build/central.ign.

Q: How do I add a new service?
A: Create services/<svc>/<svc>.bu.yml and reference its generated .ign in central.bu.yml ignition.config.merge. Then run just build.

Q: How do I test safely?
A: Use the QEMU flow: just download_fcos && just deploy_fcos_qemu. It boots using build/central.ign without touching your disks.

Q: Can I run these commands without network?
A: Most helper containers run without network; formatting and butane transpilation are offline once images are pulled. Some tasks (image downloads, FCOS image download) require network.

Q: How do I update the core user password?
A: just mkpasswd --method=yescrypt, then paste the hash into central.bu.yml under passwd.users[0].password_hash.
