class ProjectsController < ApplicationController
  include RansackPagyIndex

  before_action :set_project, only: %i[show edit update destroy switch]

  def index
    scope = policy_scope(Project)
    @q, filters = build_ransack(
      scope,
      allowed_q_keys: %i[name_or_slug_or_description_cont],
      allowed_sort_fields: %w[name slug created_at],
      default_sort: "created_at desc"
    )

    @pagy, projects = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    render inertia: "projects/index", props: {
      projects: projects.as_json(only: %i[id name slug description created_at]),
      pagination: pagy_pagination(@pagy),
      filters: filters
    }
  end

  # Endpoint para búsqueda en el dropdown (JSON)
  def search
    scope = policy_scope(Project)
    @q, = build_ransack(
      scope,
      allowed_q_keys: %i[name_or_slug_cont],
      allowed_sort_fields: %w[name slug created_at],
      default_sort: "name asc"
    )

    @pagy, projects = pagy(:offset, @q.result(distinct: true), limit: params[:limit] || 5)

    render json: {
      projects: projects.as_json(only: %i[id name slug]),
      pagination: pagy_pagination(@pagy)
    }
  end

  def show
    authorize @project
    render inertia: "projects/show", props: { project: @project.as_json(only: %i[id name slug description created_at]) }
  end

  def new
    @project = Project.new
    authorize @project
    render inertia: "projects/form", props: { project: @project.as_json(only: %i[id name description]) }
  end

  def create
    @project = current_user.projects.build(project_params)
    authorize @project

    if @project.save
      current_user.update!(current_project_id: @project.id)
      redirect_to dashboard_path, notice: I18n.t("projects.created")
    else
      render inertia: "projects/form", props: {
        project: @project.as_json(only: %i[id name description]),
        errors: @project.errors.as_json
      }
    end
  end

  def edit
    authorize @project
    render inertia: "projects/form", props: { project: @project.as_json(only: %i[id name slug description]) }
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to projects_path, notice: I18n.t("projects.updated")
    else
      render inertia: "projects/form", props: {
        project: @project.as_json(only: %i[id name slug description]),
        errors: @project.errors.as_json
      }
    end
  end

  def destroy
    authorize @project
    @project.discard

    redirect_to projects_path, notice: I18n.t("projects.deleted")
  end

  def switch
    authorize @project
    current_user.update!(current_project_id: @project.id)
    redirect_to dashboard_path, notice: I18n.t("projects.switched", name: @project.name)
  end

  private

  def set_project
    @project = Project.friendly.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description)
  end
end
