Role Name
=========

Creates, updates or deletes a host in an AWX inventory.

Requirements
------------

The `awx.awx` collection and a connection secret with an AWX access token.

Role Variables
--------------

* `name` - Name of the host in AWX (required)
* `inventory` - Inventory name, ID, or named URL the host belongs to (required)
* `description` - Description of the host
* `enabled` - Whether the host is enabled in AWX
* `variables` - Host variables as a dictionary
* `state` - `present`, `absent` or `exists`
* `connection_secret` - Name of the k8s secret holding the AWX connection details

Dependencies
------------

None.

Example Playbook
----------------

    - hosts: localhost
      roles:
        - role: host
          name: beer-host-1
          inventory: beer-inventory
          variables:
            ansible_host: 10.0.0.1

License
-------

BSD

Author Information
------------------

Ansible
