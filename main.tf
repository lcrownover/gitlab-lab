terraform {
  required_providers {
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "18.8.2"
    }
  }
}

locals {
  token = trimspace(file("${path.module}/.gitlab_admin_token"))
}

provider "gitlab" {
  token    = local.token
  base_url = "https://gitlab.local/api/v4"
  insecure = true
}

resource "gitlab_user" "participants" {
  for_each = toset([for i in range(1, 41) : format("%02d", i)])

  name              = "participant${each.key}"
  username          = "participant${each.key}"
  email             = "participant${each.key}@lab.org"
  password          = "UOISLabNumber@${each.key}"
  reset_password    = false
  skip_confirmation = true
}

resource "gitlab_project" "participant_repos" {
  for_each = gitlab_user.participants

  name                   = "myrepo"
  namespace_id           = each.value.namespace_id
  visibility_level       = "private"
  initialize_with_readme = true

  depends_on = [gitlab_user.participants]
}

resource "gitlab_group" "participant_groups" {
  for_each = toset([for i in range(1, 9) : format("group%d", i)])

  name        = each.key
  path        = each.key
  description = "Participant group ${each.key}"
}

# Map users to groups: participant01-05 -> group1, participant06-10 -> group2, etc.
locals {
  user_group_mapping = {
    for i in range(1, 41) : format("%02d", i) => format("group%d", ceil(i /
    5))
  }
}

resource "gitlab_group_membership" "participants" {
  for_each = local.user_group_mapping

  group_id     = gitlab_group.participant_groups[each.value].id
  user_id      = gitlab_user.participants[each.key].id
  access_level = "developer"

  depends_on = [gitlab_user.participants, gitlab_group.participant_groups]
}


# Each group repo should have:
# - README.md file that's simply initialized,
# - 5 "participantNN.md" files that have a simple header, for demonstrating easy collaboration
# - a "shared.md" file to demonstrate merge conflicts
resource "gitlab_project" "group_repos" {
  for_each = gitlab_group.participant_groups

  name                   = "ourrepo"
  namespace_id           = each.value.id
  visibility_level       = "private"
  initialize_with_readme = true

  depends_on = [gitlab_group.participant_groups]
}

resource "gitlab_repository_file" "group_repo_file" {
  for_each = gitlab_project.group_repos

  project        = each.value.id
  file_path      = "shared.md"
  branch         = "main"
  content        = base64encode("# shared file for demonstrating merge conflicts\n\nModify this line of text!")
  commit_message = "create shared.txt"
  encoding       = "base64"
}

locals {
  # Create a map of all participant files to create in group repos
  participant_files = {
    for i in range(1, 41) : format("participant%02d", i) => {
      group       = format("group%d", ceil(i / 5))
      participant = format("participant%02d", i)
    }
  }
}

resource "gitlab_repository_file" "participant_files" {
  for_each = local.participant_files

  project        = gitlab_project.group_repos[each.value.group].id
  file_path      = "${each.value.participant}.md"
  branch         = "main"
  content        = base64encode("# ${each.value.participant}")
  commit_message = "Add ${each.value.participant}.txt"
  encoding       = "base64"
}

