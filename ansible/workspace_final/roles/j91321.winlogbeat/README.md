ansible-role-winlogbeat
=========

[![GitHub license](https://img.shields.io/github/license/j91321/ansible-role-winlogbeat?style=flat-square)](https://github.com/j91321/ansible-role-winlogbeat/blob/master/LICENSE)
[![GitHub last commit](https://img.shields.io/github/last-commit/j91321/ansible-role-winlogbeat.svg?style=flat-square)](https://github.com/j91321/ansible-role-winlogbeat/commit/master)
![Build](https://github.com/j91321/ansible-role-winlogbeat/workflows/Test%20ansible%20role%20installation%20and%20publish%20to%20galaxy/badge.svg)
[![Twitter](https://img.shields.io/twitter/follow/j91321.svg?style=social&label=Follow)](https://twitter.com/j91321)


An Ansible role that installs winlogbeat for Windows log monitoring.

Supported platforms:

- Windows 10
- Windows Server 2019
- Windows Server 2016

Requirements
------------

None

Role Variables
--------------

Ansible variables from defaults/main.yml

```
winlogbeat_event_logs:
  channels:
    - name: Application
      ignore_older: "72h"
    - name: System
      ignore_older: "72h"
  security: true
  sysmon: false
  powershell: true
  wef: false

winlogbeat_output:
  type: "elasticsearch"
  elasticsearch:
    hosts:
      - "localhost:9200"
    security:
      enabled: false

winlogbeat_processors: |
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~

winlogbeat_service:
  install_path_64: "C:\\Program Files\\Elastic\\winlogbeat"
  install_path_32: "C:\\Program Files (x86)\\Elastic\\winlogbeat"
  version: "7.9.1"
  download: true
```

The **winlogbeat_service.download** specifies if the install zip should be downloaded from https://artifacts.elastic.co/ or is copied from Ansible server. 
If your servers don't have access to the Internet download the install zip file and place it into **.files/** folder. Don't change the zip file name.

**Caution** make sure that install_path_64 and install_path_32 end with **\\winlogbeat** last task that does cleanup removes everything else from installation path which does not contain the current winlogbeat version number!

Dependencies
------------

None.

Example Playbook
----------------

Example playbook with changed installation destination, Windows Defender log collection added, removed noisy events from security logs using processors and configured redis output.

```
- name: Install winlogbeat to workstations
  hosts:
    - workstations
  vars:
    winlogbeat_service:
       install_path_64: "C:\\Program Files\\monitoring\\winlogbeat"
       install_path_32: "C:\\Program Files (x86)\\monitoring\\winlogbeat"
       version: "7.9.1"
       download: false
    winlogbeat_event_logs:
      channels:
        - name: Application
          ignore_older: "72h"
        - name: System
          ignore_older: "72h"
        - name: Microsoft-Windows-Windows Defender/Operational
          ignore_older: "72h"
      security: true
      security_processors: |
          - drop_event.when.or:
	    - equals.winlog.event_id: 4656 # A handle to an object was requested.
	    - equals.winlog.event_id: 4658 # The handle to an object was closed.
	    - equals.winlog.event_id: 4659 # A handle to an object was requested with intent to delete.
	    - equals.winlog.event_id: 4660 # An object was deleted.
	    - equals.winlog.event_id: 4663 # An attempt was made to access an object.
	    - equals.winlog.event_id: 4664 # An attempt was made to create a hard link.
	    - equals.winlog.event_id: 4691 # Indirect access to an object was requested.
      powershell: true
      sysmon: true
      wef: false
    winlogbeat_template:
      enabled: false
    winlogbeat_general:
      tags:
        - "workstation"
        - "winlogbeat"
    winlogbeat_output:
      type: "redis"
      redis:
        hosts:
          - "192.168.24.33:6379"
        password: "my_super_long_redis_password_because_redis_is_fast"
        key: "winlogbeat-workstation"
```

License
-------

MIT

Author Information
------------------

j91321

Notes
-----

Role contains template usable with winlogbeat 6 in *./templates/winlogbeat6.yml.j2* To use this template either replace the winlogbeat.yml.j2 or modify the tasks.
