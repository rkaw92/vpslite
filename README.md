# Self-host your app on a VPS!

> I just made an app.  
> Even has a Dockerfile.  
> How do I host it?

-- developer's haiku

This project lets you run a containerized application on a cheap Virtual Private Server (VPS). It automates the set-up and maintenance of the app instance.

**This is a work in progress. It works, but I'm still polishing some stuff around the edges.**

Out-of-the-box, it gives you:
* Reverse proxy with automatic HTTPS and certificate renewal
* Private Docker registry
* App deployment via Docker images
* Virtual networking to avoid exposing your containers to the world
* Container management and auto-restart via systemd unit files
* Automatic system updates for peace of mind

![architecture diagram](vpslite.drawio.png)

## Setup

### Prerequisites
* VPS from any provider with a supported operating system
    * Tested on **Ubuntu 24.04 LTS**
* Public IP address under which the VPS is reachable
* Port 22, 80 and 443 must be open
    * often the default security policy on AWS EC2 will disallow 80, 443 - edit the policy
* 2 DNS domain names (can be subdomains):
    * one for the app deployment
    * one for the Docker image registry
    * both must point to the VPS' IP address
* Ansible installed on your computer
* SSH with public key login enabled for `root`
* Your public key added to /root/.ssh/authorized_keys

### Test connectivity
`ssh root@<yourserver>`

If this asks for a password, the Ansible playbook will encounter issues. Make sure you can log in without a password. Use ssh-agent if possible.

### Install
First, clone or download this repository:

```
git clone https://github.com/rkaw92/vpslite.git
```

Install the pre-requisites for ansible:
```
cd vpslite/ansible
ansible-galaxy install -r roles/requirements.yml
```

### Configure

This repository ships with example configuration files. You will need to edit them:

```
cp inventory.example inventory
cp -r group_vars.example group_vars
```

Now, edit these files according to the comments:
* inventory
* group_vars/all/base_vars

### Run the base playbook

```sh
ansible-playbook base.yaml
```

If all goes well, a reverse proxy server should be started, already serving HTTPS on your domain! For now, it will return HTTP 502 Bad Gateway, because we have not deployed the app server yet.

You should now be able to do:
```
docker login <myrepositorydomain>
```

* Username: `dev`
* Password: `(the value that you set in base_vars)`

### Build an app image

* `docker build . -t <myrepositorydomain>/<myimage>:latest`
* `docker push <myrepositorydomain>/<myimage>:latest`

The application must run HTTP on port 3000. Additionally, the Dockerfile should include an EXPOSE statement for the port. This is where the reverse proxy will connect.

For an example Dockerfile that can be used for building a working Node.js app, see the directory `app-example`.

### Run the app deployment playbook

First, edit `group_vars/all/app_vars` to point to the app image. Use the fully-qualified image name, like in the example.

```
ansible-playbook app.yaml
```

## Ongoing maintenance

### Security updates

The base playbook already installs and enables `unattended-upgrades`, so your host system will receive security updates.

Other infrastructure containers are not auto-updated right now. See GitHub Issues for more information.

### Application updates

```sh
podman pull <myappimage>
systemctl restart app@1
```

### Logs

... TBD

## License
MIT