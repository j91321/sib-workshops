# Introduction

## Create python virtual environment

```sh
python3 -m venv venv-ansible
```

## Activate python virtual environment

```sh
source ./venv-ansible/bin/activate
```

## Upgrade pip

Note: without upgrading pip, installation of cryptography package may fail because of rust dependencies.

```sh
pip install --upgrade pip
```

## Install Ansible, Ansible Lint and Molecule

```sh
pip install ansible ansible-lint 'molecule[docker]'
```

## (Optional) Create SSH key if needed

```sh
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "comments go here"
```

## (Optional) Start ssh-agent

```sh
eval `ssh-agent`
ssh-add
```

## Create inventory

Inventory can have different formats the simplest is the INI format, but you can have it in YAML or a dynamic inventory.

Create file named inventory with following content (replace IP with your VM):

```ini
[elastic]
192.168.40.132
192.168.40.133

[kibana]
192.168.40.134
```

## Ansible ping

```sh
ansible -i inventory -m ping all -u ansible
```

## Set default user in inventory

```ini
[all:vars]
ansible_user = ansible
```

## Adhoc commands

### Command module

```sh
ansible all -i inventory -m command -a "df -h"
```

or

```sh
ansible all -i inventory -a "df -h"
```

Module `-m command` is used by default. 

*Note: You can't use pipes or redirection with command module. Use `-m shell` if you need those (not recommended).* 

### Specifying number of forks

```sh
ansible all -i inventory -a "df -h" -f 20
```

*Default number of forks is 5*

### Background tasks

Run command in background with timeout 3600s and no results polling. 

```sh
ansible all -B 3600 -P 0 -a "df -h"
```

Check for result

```sh
ansible kibana -m async_status -a "jid=<JOBID>"
```

# First playbook

TODO


# Using Ansible Roles and testing with Molecule

## Initialize new role with Molecule

(in `./roles`)

```sh
molecule init role acme.kibana --driver-name docker
```

## Create tasks

In `tasks/main.yml`

```yaml
---
- name: Add Elasticsearch 7.X repo key
  apt_key:
    id: 46095ACC8548582C1A2699A9D27D666CD88E42B4
    url: "https://artifacts.elastic.co/GPG-KEY-elasticsearch"
    state: present

- name: Add Elasticsearch 7.X repo
  apt_repository:
    repo: deb https://artifacts.elastic.co/packages/7.x/apt stable main
    filename: elastic-7-repo.list
    state: present

- name: Install Kibana
  apt:
    name: kibana={{ kibana_version }}
    update_cache: true
    state: present

- name: Configure Kibana
  template:
    src: "kibana.yml.j2"
    dest: "/etc/kibana/kibana.yml"
  notify: restart kibana

- name: Enable Kibana service
  systemd:
    name: kibana
    enabled: true
    state: started
```

## Create handler to restart service on config change

In `handlers/main.yml` put:

```yaml
---
- name: restart kibana
  systemd:
    name: kibana
    state: restarted
```

## Create Kibana config template

In `templates/kibana.yml.j2` put:

```yaml
#Ansible Managed
server.host: "{{ kibana_bind }}"
server.port: "{{ kibana_port }}"
elasticsearch.hosts: {{ kibana_elasticsearch_hosts }}
```

## Create default values for variables

In `defaults/main.yml` put:

```yaml
---
kibana_version: 7.17.0
kibana_bind: "0.0.0.0"
kibana_port: 5601
kibana_elasticsearch_hosts: ["http://localhost:9200"]
```

## Configure Molecule

### Prepare container settings

Modify `molecule/default/molecule.yml` to look like this:

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: geerlingguy/docker-ubuntu2004-ansible
    tmpfs:
      - /run
      - /tmp
    capabilities:
      - SYS_ADMIN
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    privileged: true
    command: "/lib/systemd/systemd"
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

*Note: Docker images normally don't have systemd. There is no need for it since container should run only one service.* 

*Our role however uses systemd so we need special image that has systemd support in order to test it and we also need to make a few changes to the container settings. This means we have to run the container as privileged. Normally you don't want to do this unless absolutely necessary. Privileged containers can do anything a root could do on your host system!*

### Add pre_task setp to converge.yml playbook

Add following to `molecule/default/converge,yml`, before the `tasks` step.

```yaml
  pre_tasks:
    - name: Install GPG
      apt:
        name: gpg-agent
        update_cache: true
        state: present
      when: ansible_os_family == 'Debian'
```