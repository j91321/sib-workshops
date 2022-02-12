# Introduction

## Create python virtual environment

```
python3 -m venv venv-ansible
```

## Activate python virtual environment

```
source ./venv-ansible/bin/activate
```

## Upgrade pip

Note: without upgrading pip, installation of cryptography package may fail because of rust dependencies.

```
pip install --upgrade pip
```

## Install Ansible, Ansible Lint and Molecule

```
pip install ansible ansible-lint molecule
```

## (Optional) Create SSH key if needed

```
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "comments go here"
```

## (Optional) Start ssh-agent

```
eval `ssh-agent`
ssh-add
```

## Create inventory

Inventory can have different formats the simplest is the INI format, but you can have it in YAML or a dynamic inventory.

Create file named inventory with following content (replace IP with your VM):

```
[elastic]
192.168.40.132
192.168.40.133

[kibana]
192.168.40.134
```

## Ansible ping

```
ansible -i inventory -m ping all -u ansible
```

## Set default user in inventory

```
[all:vars]
ansible_user = ansible
```

## Ad hoc command

- forks
- limit
- backgroundtasks

# First playbook
