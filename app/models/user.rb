# frozen_string_literal: true

class User < ApplicationRecord
  rolify
  include Discard::Model
  self.discard_column = :deleted_at

  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable

  has_many :projects, dependent: :destroy
  belongs_to :current_project, class_name: "Project", optional: true

  validates :full_name, presence: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[id full_name email created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[roles projects current_project]
  end

  GLOBAL_ROLES = %i[super_admin admin blog_admin blog_writer].freeze
  PROJECT_ROLES = %i[owner coworker client].freeze

  def super_admin? = has_role?(:super_admin)
  def admin? = has_role?(:admin)
  def global_admin? = super_admin? || admin?

  def owner_of?(project) = has_role?(:owner, project)
  def member_of?(project) = roles.where(resource: project).exists?

  def accessible_projects
    if global_admin?
      Project.kept.order(created_at: :desc)
    else
      owned_projects
    end
  end

  def owned_projects
    project_ids = roles
      .where(resource_type: "Project")
      .order(created_at: :desc)
      .pluck(:resource_id)

    Project.kept.where(id: project_ids).in_order_of(:id, project_ids)
  end

  def last_accessible_project
    owned_projects.first
  end
end
