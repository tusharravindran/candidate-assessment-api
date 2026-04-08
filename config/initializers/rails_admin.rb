RailsAdmin.config do |config|

  # ── Authentication ──────────────────────────────────────────────────────────
  # Use the AdminUser Devise model (session-based, separate from tenant recruiters).
  config.authenticate_with do
    warden.authenticate! scope: :admin_user
  end

  config.current_user_method(&:current_admin_user)

  config.asset_source = :sprockets

  # ── Navigation ──────────────────────────────────────────────────────────────
  config.navigation_static_links = {
    "API Docs" => "/api/v1/health"
  }

  # ── Models to expose ────────────────────────────────────────────────────────
  config.included_models = %w[Organization Recruiter Assessment Invitation AdminUser]

  # ── Organization ─────────────────────────────────────────────────────────────
  config.model "Organization" do
    label "Organization"
    label_plural "Organizations"
    navigation_label "Tenants"
    navigation_icon "fas fa-building"

    list do
      field :id
      field :name
      field :slug
      field :domain
      field :plan
      field :active do
        formatted_value { bindings[:object].active? ? "✅ Active" : "🚫 Suspended" }
      end
      field :recruiters_count do
        label "Users"
        formatted_value { bindings[:object].recruiters.count }
        sortable false
      end
      field :created_at
    end

    show do
      field :id
      field :name
      field :slug
      field :domain
      field :plan
      field :active
      field :settings
      field :created_at
      field :updated_at
      field :recruiters
      field :assessments
    end

    edit do
      field :name
      field :domain do
        help "Optional. Used for domain-based tenant identification."
      end
      field :plan do
        partial "plan_select"
        help "Subscription plan. Changing this affects feature gating."
      end
      field :active do
        help "Uncheck to suspend the organization. All recruiter logins will be blocked immediately."
      end
      field :settings, :json_editor
    end

    # Custom bulk actions
    action :activate_organization do
      action_name :activate
      only Organization
      http_methods [:post]
      controller do
        proc do
          @objects.each { |org| org.update!(active: true) }
          flash[:success] = "#{@objects.size} organization(s) activated."
          redirect_to back_or_index
        end
      end
    end

    action :suspend_organization do
      action_name :suspend
      only Organization
      http_methods [:post]
      controller do
        proc do
          @objects.each { |org| org.update!(active: false) }
          flash[:success] = "#{@objects.size} organization(s) suspended."
          redirect_to back_or_index
        end
      end
    end
  end

  # ── Recruiter (tenant user) ──────────────────────────────────────────────────
  config.model "Recruiter" do
    label "Recruiter"
    label_plural "Recruiters"
    navigation_label "Tenants"
    navigation_icon "fas fa-users"

    list do
      field :id
      field :name
      field :email
      field :role
      field :organization
      field :sign_in_count
      field :current_sign_in_at
      field :created_at
    end

    show do
      field :id
      field :name
      field :email
      field :role
      field :organization
      field :sign_in_count
      field :current_sign_in_at
      field :last_sign_in_at
      field :current_sign_in_ip
      field :created_at
    end

    edit do
      field :name
      field :email
      field :role do
        help "admin — can review free-text answers and manage org. member — standard recruiter."
      end
      field :organization
      field :password do
        help "Leave blank to keep existing password."
      end
      field :password_confirmation
    end
  end

  # ── Assessment ───────────────────────────────────────────────────────────────
  config.model "Assessment" do
    label "Assessment"
    navigation_label "Content"
    navigation_icon "fas fa-clipboard-list"

    list do
      field :id
      field :title
      field :organization
      field :status
      field :time_limit_minutes
      field :passing_score
      field :created_at
    end

    show do
      field :id
      field :title
      field :description
      field :organization
      field :recruiter
      field :status
      field :time_limit_minutes
      field :passing_score
      field :questions
      field :created_at
    end

    edit do
      # Assessments are intentionally read-only in platform admin.
      # Mutations happen inside the recruiter workspace.
      read_only do
        field :title
        field :status
        field :organization
      end
    end
  end

  # ── Invitation ───────────────────────────────────────────────────────────────
  config.model "Invitation" do
    label "Invitation"
    navigation_label "Content"
    navigation_icon "fas fa-envelope"

    list do
      field :id
      field :candidate_email
      field :candidate_name
      field :organization
      field :assessment
      field :used
      field :expires_at
      field :created_at
    end

    show do
      field :id
      field :candidate_email
      field :candidate_name
      field :token
      field :organization
      field :assessment
      field :recruiter
      field :used
      field :expires_at
      field :created_at
    end
  end

  # ── Platform Admin Users ──────────────────────────────────────────────────────
  config.model "AdminUser" do
    label "Admin User"
    label_plural "Admin Users"
    navigation_label "Platform"
    navigation_icon "fas fa-shield-alt"

    list do
      field :id
      field :email
      field :sign_in_count
      field :current_sign_in_at
      field :created_at
    end

    edit do
      field :email
      field :password do
        help "Leave blank to keep existing password."
      end
      field :password_confirmation
    end
  end

end
