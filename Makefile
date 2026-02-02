compose_up:
	@echo "Starting compose stack..."
	@docker compose up -d
	@echo "Stack running"

compose_down:
	@echo "Stopping compose stack..."
	@docker compose down
	@echo "Stack stopped"

compose_down_delete:
	@echo "Stopping compose stack and deleting volumes..."
	@docker compose down -v
	@echo "Stack stopped and volumes deleted"

wait_for_gitlab:
	@echo "Waiting for GitLab to be fully ready..."
	@until curl -sk 'https://gitlab.local/-/readiness?all=1' 2>/dev/null | jq -r .status | grep "ok" >/dev/null; do \
			sleep 10; \
			echo "Still waiting..."; \
	done
	@sleep 60 # extra because i don't think the runner is the last thing
	@echo "GitLab is ready"

create_admin_token:
	@if [ -f .gitlab_admin_token ]; then \
		echo "Token already exists"; \
		exit 0; \
	fi
	@echo "Generating admin token..."
	@docker exec gitlab gitlab-rails runner " \
		token = User.find_by_username('root').personal_access_tokens.create!( \
		  name: 'terraform-admin', \
		  impersonation: false, \
		  scopes: [:api, :sudo, :admin_mode], \
		  expires_at: 365.days.from_now \
		); \
		puts token.token" | tail -1 | tee .gitlab_admin_token
	  @echo "Saved admin token to .gitlab_admin_token"

disable_signups:
	@curl -sk --request PUT \
		--header "PRIVATE-TOKEN: $(cat .gitlab_admin_token)" \
		--header "Content-Type: application/json" \
		--data '{"signup_enabled": false}' \
		"https://gitlab.local/api/v4/application/settings"


apply_terraform:
	@echo "Applying Terraform..."
	@terraform init
	@terraform apply -auto-approve
	@echo "Terraform applied"

clean_state:
	@echo "Deleting state..."
	@rm -rf terraform* .gitlab_admin_token .terraform*
	@echo "State deleted"

run: compose_up wait_for_gitlab create_admin_token disable_signups apply_terraform

stop: compose_down

destroy: compose_down_delete clean_state
