class UsersController < ApplicationController
  include RansackPagyIndex

  before_action :set_user, only: %i[show update destroy remove_from_project]

  def index
    authorize User
    scope = policy_scope(User)
    @q, filters = build_ransack(
      scope,
      allowed_q_keys: %i[full_name_or_email_cont],
      allowed_sort_fields: %w[full_name email created_at],
      default_sort: "created_at desc"
    )

    @pagy, users = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    render inertia: "users/index", props: {
      users: users.as_json(only: %i[id email full_name created_at]),
      pagination: pagy_pagination(@pagy),
      filters: filters,
      can_invite: policy(User).invite?,
      can_remove_from_project: policy(User).remove_from_project?,
      can_destroy: policy(User).destroy?,
      current_user_id: current_user.id
    }
  end

  def show
    authorize @user
    render inertia: "users/show", props: { user: user_json(@user) }
  end

  def new_invitation
    authorize User, :invite?
    render inertia: "users/invite", props: {
      current_project: current_project.as_json(only: %i[id name slug])
    }
  end

  def invite
    authorize User, :invite?

    email = invitation_params[:email]
    invite_to_project = invitation_params[:invite_to_project] == "true"

    existing_user = User.find_by(email: email)

    if existing_user
      invite_existing_user(existing_user, invite_to_project)
    else
      invite_new_user(email, invite_to_project)
    end
  end

  def update
    authorize @user

    if @user.update(user_params)
      redirect_to users_path, notice: I18n.t("users.updated")
    else
      render inertia: "users/show", props: {
        user: user_json(@user),
        errors: @user.errors.as_json
      }
    end
  end

  def destroy
    authorize @user
    @user.discard
    redirect_to users_path, notice: I18n.t("users.deleted")
  end

  def remove_from_project
    authorize @user

    # Quitar todos los roles del usuario en el proyecto actual
    @user.roles.where(resource: current_project).destroy_all

    # Si el proyecto actual era su current_project, limpiarlo
    # (auto_assign_project en ApplicationController lo reasignará)
    if @user.current_project_id == current_project.id
      @user.update_column(:current_project_id, nil)
    end

    redirect_to users_path, notice: I18n.t("users.removed_from_project")
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:full_name, :email)
  end

  def invitation_params
    params.permit(:email, :invite_to_project)
  end

  # Roles permitidos para asignar a usuarios en un proyecto
  ALLOWED_INVITATION_ROLES = %w[coworker client].freeze

  def safe_invitation_role
    role = params[:role].to_s
    ALLOWED_INVITATION_ROLES.include?(role) ? role : "coworker"
  end

  def user_json(user)
    user.as_json(only: %i[id email full_name created_at]).merge(
      roles: user.roles.where(resource: current_project).pluck(:name)
    )
  end

  def invite_existing_user(user, invite_to_project)
    if invite_to_project && current_project
      user.add_role(safe_invitation_role, current_project)
      redirect_to users_path, notice: I18n.t("users.added_to_project", email: user.email)
    else
      redirect_to users_path, alert: I18n.t("users.already_exists")
    end
  end

  def invite_new_user(email, invite_to_project)
    user = User.invite!({ email: email, full_name: email.split("@").first }, current_user)

    if user.persisted?
      if invite_to_project && current_project
        user.add_role(safe_invitation_role, current_project)
        user.update!(current_project_id: current_project.id)
      end
      redirect_to users_path, notice: I18n.t("users.invitation_sent", email: email)
    else
      render inertia: "users/invite", props: {
        current_project: current_project.as_json(only: %i[id name slug]),
        errors: user.errors.as_json
      }
    end
  end
end
