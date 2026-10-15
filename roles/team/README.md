Role Name
=========

Creates an AWX team, grants AWX roles to the team and adds usernames as team
members. Because members inherit the roles of their team, adding a user to the
team is enough to give that user the granted permissions.

Role Variables
--------------

* `name` - AWX team name (required)
* `new_name` - Optional new name, used to rename an existing team
* `organization` - Organization the team belongs to (required)
* `description` - Optional team description
* `users` - List of AWX usernames added as team members
* `roles` - List of role grants, each with a `role` name, exactly one of
  `organization`, `inventory`, `job_template`, `workflow`, `credential`,
  `project`, `instance_group` and an optional `state` (`present` or `absent`)
* `preserve_existing_users` - When `true`, members not listed in `users` are kept
* `connection_secret` - Name of the k8s secret holding the AWX host and token (required)
* `state` - `present`, `absent` or `exists`

The declared `users` are synchronized with AWX unless `preserve_existing_users`
is `true`, in which case only the declared usernames are added and no existing
member is removed.
