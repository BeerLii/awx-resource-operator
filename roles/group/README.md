Role Name
=========

Creates, updates or deletes a host group in an AWX inventory.

Role Variables
--------------

* `name` and `inventory` are required.
* `managed_hosts` creates or updates hosts in the inventory and associates them
  with the group automatically. Each entry supports `name` (required),
  `description`, `enabled` (default `true`), and `variables`. Use this to manage
  a group and its hosts with one resource instead of separate `AnsibleHost`
  resources.
* `hosts` lists existing AWX host names, IDs, or named URLs to associate with
  the group. Managed host names do not need to be repeated here.
* `children` lists child group names to associate with the group.
* `preserve_existing_hosts` and `preserve_existing_children` prevent omitted existing associations from being removed.
* `variables`, `description`, `state`, and `connection_secret` configure the group.
* Deleting the resource removes the group but leaves `managed_hosts` in the
  inventory, since a host may be shared by multiple groups.
