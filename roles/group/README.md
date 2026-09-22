Role Name
=========

Creates, updates or deletes a host group in an AWX inventory.

Role Variables
--------------

* `name` and `inventory` are required.
* `hosts` lists host names to associate with the group.
* `children` lists child group names to associate with the group.
* `preserve_existing_hosts` and `preserve_existing_children` prevent omitted existing associations from being removed.
* `variables`, `description`, `state`, and `connection_secret` configure the group.
