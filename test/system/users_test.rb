# frozen_string_literal: true

require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  # === Setup ===
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @test_project = projects(:test_project)
  end

  # =============================================================================
  # Tests: Visibilidad del menú de usuarios según rol
  # =============================================================================

  test "super_admin can see users menu in navigation" do
    sign_in_with_form(@super_admin)

    assert_selector "[data-testid='nav-drawer']"

    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "admin can see users menu in navigation" do
    sign_in_with_form(@admin)

    # Wait for the navigation to render
    assert_selector "[data-testid='nav-drawer']"

    # Open the drawer to see navigation items
    find("[data-testid='nav-hamburger']").click

    # Wait for the drawer to open and assert the users menu item
    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "owner can see users menu in navigation" do
    sign_in_with_form(@owner)

    # Wait for the navigation to render
    assert_selector "[data-testid='nav-drawer']"

    # Open the drawer to see navigation items
    find("[data-testid='nav-hamburger']").click

    # Wait for the drawer to open and assert the users menu item
    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "coworker cannot see users menu in navigation" do
    sign_in_with_form(@coworker)

    # Wait for the navigation to render
    assert_selector "[data-testid='nav-drawer']"

    # Open the drawer to see navigation items
    find("[data-testid='nav-hamburger']").click

    # Wait for the drawer to open and assert no users menu item
    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-users']"
    end
  end

  test "client cannot see users menu in navigation" do
    sign_in_with_form(@client)

    # Wait for the navigation to render
    assert_selector "[data-testid='nav-drawer']"

    # Open the drawer to see navigation items
    find("[data-testid='nav-hamburger']").click

    # Wait for the drawer to open and assert no users menu item
    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-users']"
    end
  end

  # =============================================================================
  # Tests: Acceso directo a /users según rol
  # =============================================================================

  test "super_admin can access users list directly" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_selector "[data-testid='users-table']"
  end

  test "owner can access users list directly" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-table']"
  end

  test "coworker is redirected when trying to access users directly" do
    sign_in_with_form(@coworker)

    visit users_path

    # Debería ser redirigido y NO ver la tabla de usuarios
    assert_no_selector "[data-testid='users-table']"
  end

  # =============================================================================
  # Tests: Botón de invitar usuarios
  # =============================================================================

  test "super_admin can see invite button" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  test "owner can see invite button" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  test "admin can see invite button" do
    sign_in_with_form(@admin)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  # =============================================================================
  # Tests: Listado de usuarios - Solo usuarios del proyecto actual
  # =============================================================================

  test "users list shows only users from current project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-table']"

    # Usuarios del proyecto test_project deben aparecer
    assert_text @coworker.full_name
    assert_text @client.full_name

    # El outsider no tiene rol en test_project, no debe aparecer
    outsider = users(:outsider_user)
    assert_no_text outsider.full_name
  end

  # =============================================================================
  # Tests: Desvincular usuario del proyecto (owner/admin)
  # =============================================================================

  test "owner can see unlink button for users in project" do
    sign_in_with_form(@owner)

    visit users_path

    # El owner debe ver el botón de desvincular para coworker
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "admin can see unlink button for users in project" do
    sign_in_with_form(@admin)

    visit users_path

    # El admin debe ver el botón de desvincular
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "owner can unlink a user from the project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_text @coworker.full_name

    # Click en desvincular
    find("[data-testid='users-row-#{@coworker.id}-btn-unlink']").click

    # Confirmar en el diálogo
    assert_selector "[data-testid='users-dialog-unlink-btn-confirm']"
    find("[data-testid='users-dialog-unlink-btn-confirm']").click

    # El usuario ya no debe aparecer en la lista (fue desvinculado del proyecto)
    assert_no_text @coworker.full_name
  end

  # =============================================================================
  # Tests: Eliminar usuario (solo super_admin)
  # =============================================================================

  test "super_admin can see delete button for users" do
    sign_in_with_form(@super_admin)

    visit users_path

    # Super admin debe ver el botón de eliminar
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"
  end

  test "owner cannot see delete button (only unlink)" do
    sign_in_with_form(@owner)

    visit users_path

    # Owner NO debe ver el botón de eliminar
    assert_no_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"

    # Pero SÍ debe ver el botón de desvincular
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "admin cannot see delete button (only unlink)" do
    sign_in_with_form(@admin)

    visit users_path

    # Admin NO debe ver el botón de eliminar
    assert_no_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"

    # Pero SÍ debe ver el botón de desvincular
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "super_admin can delete a user" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_text @coworker.full_name

    # Click en eliminar
    find("[data-testid='users-row-#{@coworker.id}-btn-delete']").click

    # Confirmar en el diálogo
    assert_selector "[data-testid='users-dialog-delete-btn-confirm']"
    find("[data-testid='users-dialog-delete-btn-confirm']").click

    # El usuario ya no debe aparecer en la lista
    assert_no_text @coworker.full_name
  end

  # =============================================================================
  # Tests: Ver información de usuario
  # =============================================================================

  test "owner can view user details" do
    sign_in_with_form(@owner)

    visit users_path
    find("[data-testid='users-row-#{@coworker.id}-btn-view']").click

    assert_current_path user_path(@coworker)
    assert_text @coworker.full_name
    assert_text @coworker.email
  end

  # =============================================================================
  # Tests: Invitar usuario
  # =============================================================================

  test "owner can navigate to invite form" do
    sign_in_with_form(@owner)

    visit users_path
    find("[data-testid='users-btn-invite']").click

    assert_current_path new_invitation_users_path
    assert_selector "[data-testid='users-input-email']"
  end

  test "owner can send invitation to new user" do
    sign_in_with_form(@owner)

    visit new_invitation_users_path

    # Llenar el formulario de invitación (solo email, el rol se selecciona)
    fill_in_field "[data-testid='users-input-email'] input", with: "newuser@example.com"

    # El checkbox de invitar al proyecto ya viene marcado por defecto
    # Seleccionar rol (colaborador/coworker por defecto)
    find("[data-testid='users-select-role']").click
    find(".v-list-item", text: t("roles.coworker")).click

    # Enviar invitación
    find("[data-testid='users-invite-form-btn-submit']").click

    # Debería redirigir a la lista de usuarios
    assert_current_path users_path

    # El nuevo usuario invitado debería aparecer
    assert_text "newuser@example.com"
  end

  # =============================================================================
  # Tests: Usuario no puede modificarse a sí mismo
  # =============================================================================

  test "owner cannot unlink themselves from project" do
    sign_in_with_form(@owner)

    visit users_path

    # El owner NO debe ver el botón de desvincular en su propia fila
    assert_no_selector "[data-testid='users-row-#{@owner.id}-btn-unlink']"
  end

  test "super_admin cannot delete themselves" do
    sign_in_with_form(@super_admin)

    visit users_path

    # Super admin NO debe ver el botón de eliminar en su propia fila
    assert_no_selector "[data-testid='users-row-#{@super_admin.id}-btn-delete']"
  end

  # =============================================================================
  # Tests: Global admin auto-assignment
  # =============================================================================

  test "global admin without current_project is auto-assigned to existing project" do
    # Remove current_project from super_admin
    @super_admin.update_column(:current_project_id, nil)

    sign_in_with_form(@super_admin)

    # Should NOT be redirected to new project page
    assert_no_current_path new_project_path

    # Should have access to dashboard/navigation
    assert_selector "[data-testid='nav-drawer']"

    # Verify current_project was auto-assigned
    @super_admin.reload
    assert_not_nil @super_admin.current_project_id
  end

  private

  def t(key, **options)
    I18n.t(key, scope: :frontend, **options)
  end
end
