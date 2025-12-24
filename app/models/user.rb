class User < ApplicationRecord
  rolify
  include Discard::Model
  self.discard_column = :deleted_at

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable

  # Associations
  has_many :projects, dependent: :destroy
  belongs_to :current_project, class_name: "Project", optional: true

  validates :full_name, presence: true

  # Roles globales
  GLOBAL_ROLES = %i[super_admin admin blog_admin blog_writer].freeze
  # Roles por proyecto
  PROJECT_ROLES = %i[owner coworker client].freeze

  # Helpers para roles globales
  def super_admin? = has_role?(:super_admin)
  def admin? = has_role?(:admin)
  def global_admin? = super_admin? || admin?

  # Helpers para roles de proyecto
  def owner_of?(project) = has_role?(:owner, project)
  def member_of?(project) = roles.where(resource: project).exists?

  # Proyectos accesibles (donde es miembro)
  def accessible_projects
    if global_admin?
      Project.kept
    else
      Project.kept.where(id: roles.where(resource_type: "Project").pluck(:resource_id))
    end
  end
end
