Role Name
=========

Creates an AWX execution environment. An execution environment is the
container image that AWX uses to run jobs, and it is scoped to an
organization.

Role Variables
--------------

* `name` - AWX execution environment name (required)
* `organization` - Organization name, ID, or named URL the execution environment belongs to (required)
* `image` - Container image (registry/image:tag) used as the execution environment (required)
* `description` - Optional execution environment description
* `credential` - Optional registry credential name, ID, or named URL used to pull the image
* `pull` - `always`, `missing` (default) or `never`
* `connection_secret` - Name of the k8s secret holding the AWX host and token (required)
* `state` - `present`, `absent` or `exists`
