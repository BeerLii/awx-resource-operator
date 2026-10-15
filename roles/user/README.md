Role Name
=========

Grants AWX user type permissions (System Administrator / System Auditor) to a user
identified by `username`. The user must already exist in AWX unless a
`password_secret` is supplied, in which case the user is created when missing.

The role only owns the AWX user *type*, never the user record itself. Deleting the
`AnsibleUser` resource (the operator finalizer runs the role with `state: absent`)
revokes the System Administrator / System Auditor user types and leaves the AWX
user in place as a normal user. The AWX user is never deleted, so the
login-provisioned account and its password keep working.

Role Variables
--------------

* `username` - AWX username to manage (required)
* `connection_secret` - Name of the k8s secret holding the AWX host and token (required)
* `is_superuser` - Grant or revoke the System Administrator (superuser) user type
* `is_system_auditor` - Grant or revoke the System Auditor user type
* `first_name`, `last_name`, `email` - Optional profile fields
* `organization` - Optional organization the user should belong to
* `password_secret` - Optional k8s secret (key `password`) used to create or update the user
* `state` - `present`, `absent` or `exists`. `absent` revokes the user types
  (`is_superuser: false`, `is_system_auditor: false`) and keeps the user as a
  normal user; it does not delete the AWX user.

`is_superuser` and `is_system_auditor` are only sent to AWX when they are set in
the resource, so the operator never demotes an existing user type by accident.
