class ProjectsController < ApplicationController
  skip_before_action :set_current_tenant, only: %i[index search new create]
  before_action :set_project, only: %i[show edit update destroy switch]

  PAGINATION_KEYS = %i[count page limit pages previous next from to].freeze

  def index
    @q = policy_scope(Project).ransack(params[:q])
    @pagy, projects = pagy(:offset, @q.result(distinct: true))

    render inertia: "projects/index", props: {
      projects: projects.as_json(only: %i[id name slug description]),
      pagination: @pagy.data_hash(data_keys: PAGINATION_KEYS),
      filters: params[:q] || {}
    }
  end

  # Endpoint para búsqueda en el dropdown (JSON)
  def search
    @q = policy_scope(Project).ransack(params[:q])
    @pagy, projects = pagy(:offset, @q.result(distinct: true), limit: params[:limit] || 5)

    render json: {
      projects: projects.as_json(only: %i[id name slug]),
      pagination: @pagy.data_hash(data_keys: PAGINATION_KEYS)
    }
  end

  def show
    authorize @project
    render inertia: "projects/show", props: { project: @project.as_json(only: %i[id name slug description]) }
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
