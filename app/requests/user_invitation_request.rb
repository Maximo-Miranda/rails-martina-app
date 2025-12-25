class UserInvitationRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :email, :invite_to_project, :role

  ALLOWED_INVITATION_ROLES = %w[coworker client].freeze

  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
  validates :invite_to_project, inclusion: { in: [ true, false, "true", "false" ] }, allow_nil: true
  validates :role, inclusion: { in: ALLOWED_INVITATION_ROLES }, allow_nil: true

  def safe_role
    return "coworker" if role.blank?
    ALLOWED_INVITATION_ROLES.include?(role) ? role : "coworker"
  end

  def invite_to_project?
    invite_to_project == true || invite_to_project == "true"
  end
end
