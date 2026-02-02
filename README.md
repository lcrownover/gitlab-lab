# GitLab Lab Environment

A containerized GitLab CE instance with pre-provisioned users and repositories for workshop/training use.

## Prerequisites

- Docker and Docker Compose
- Terraform
- `jq` (for readiness checks)
- Add `gitlab.local` to `/etc/hosts`:
  ```
  127.0.0.1 gitlab.local
  ```

## What Gets Created

- **40 participant users**: `participant01` through `participant40`
- **Individual repos**: Each participant gets their own `myrepo`
- **8 groups**: `group1` through `group8` (5 participants each)
- **Group repos**: Each group has an `ourrepo` with:
  - `shared.md` for merge conflict exercises
  - Individual `participantNN.md` files

### Group Assignments

| Group   | Participants      |
|---------|-------------------|
| group1  | participant01-05  |
| group2  | participant06-10  |
| group3  | participant11-15  |
| group4  | participant16-20  |
| group5  | participant21-25  |
| group6  | participant26-30  |
| group7  | participant31-35  |
| group8  | participant36-40  |

## Setup

```bash
make run
```

This will:
1. Start the GitLab container
2. Wait for GitLab to be ready
3. Generate an admin API token
4. Disable public signups
5. Apply Terraform to create users, groups, and repos

GitLab will be available at https://gitlab.local (accept the self-signed certificate warning).

### Credentials

- **Admin**: `root` / `UOISLabSuperPass!`
- **Participants**: `participantNN` / `UOISLabNumber@NN` (e.g., `participant01` / `UOISLabNumber@01`)

## Teardown

```bash
make destroy
```

This will:
1. Stop the GitLab container
2. Delete all Docker volumes
3. Clean up Terraform state and tokens

## Other Commands

| Command | Description |
|---------|-------------|
| `make stop` | Stop GitLab without deleting data |
| `make compose_up` | Start GitLab container only |
| `make apply_terraform` | Re-run Terraform provisioning |
