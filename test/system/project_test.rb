# frozen_string_literal: true

require "application_system_test_case"

class ProjectTest < ApplicationSystemTestCase
  # === Setup ===
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @test_project = projects(:test_project)
    @other_project = projects(:other_project)
  end

  # =============================================================================
  # Tests: Admin global ve todos los proyectos
  # =============================================================================

  test "super_admin can see all projects in the list" do
    sign_in_with_form(@super_admin)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    # Super admin debe ver todos los proyectos
    assert_text @test_project.name
    assert_text @other_project.name
  end

  test "admin can see all projects in the list" do
    sign_in_with_form(@admin)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    # Admin también debe ver todos los proyectos
    assert_text @test_project.name
    assert_text @other_project.name
  end

  test "owner can see only their accessible projects" do
    sign_in_with_form(@owner)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    # Owner debe ver los proyectos donde tiene rol
    assert_text @test_project.name
    assert_text @other_project.name  # confirmed_user es owner de ambos
  end

  test "coworker can see only projects where they have a role" do
    sign_in_with_form(@coworker)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    # Coworker solo debe ver test_project (donde tiene rol coworker)
    assert_text @test_project.name
    assert_no_text @other_project.name
  end

  # =============================================================================
  # Tests: Dropdown de cambio de proyectos (ProjectSwitcher)
  # =============================================================================

  test "super_admin can see all projects in the switcher dropdown" do
    sign_in_with_form(@super_admin)

    # Abrir el dropdown del switcher
    find("[data-testid='switcher-btn']").click
    assert_selector "[data-testid='switcher-menu']"

    # Super admin debe ver todos los proyectos en el dropdown
    assert_selector "[data-testid='switcher-project-#{@test_project.slug}']"
    assert_selector "[data-testid='switcher-project-#{@other_project.slug}']"
  end

  test "owner can switch projects using the switcher" do
    sign_in_with_form(@owner)

    # El proyecto actual debería mostrarse en el switcher
    assert_selector "[data-testid='switcher-btn']"

    # Abrir el dropdown del switcher
    find("[data-testid='switcher-btn']").click
    assert_selector "[data-testid='switcher-menu']"

    # Cambiar al otro proyecto
    find("[data-testid='switcher-project-#{@other_project.slug}']").click

    # Verificar que cambió al proyecto (debería redirigir al dashboard)
    assert_current_path dashboard_path

    # El nombre del proyecto nuevo debería aparecer en el switcher
    assert_text @other_project.name
  end

  # =============================================================================
  # Tests: Crear proyecto
  # =============================================================================

  test "authenticated user can create a new project" do
    sign_in_with_form(@owner)

    visit new_project_path
    assert_selector "[data-testid='projects-input-name']"

    # Llenar el formulario
    fill_in_field "[data-testid='projects-input-name'] input", with: "Mi Nuevo Proyecto"
    fill_in_field "[data-testid='projects-input-description'] textarea", with: "Descripción del proyecto de prueba"

    # Enviar formulario
    find("[data-testid='projects-form-btn-submit']").click

    # Debería redirigir al dashboard con el nuevo proyecto activo
    assert_current_path dashboard_path

    # Verificar que el proyecto se creó visitando la lista
    visit projects_path
    assert_text "Mi Nuevo Proyecto"
  end

  test "can navigate to new project from projects list" do
    sign_in_with_form(@owner)

    visit projects_path
    find("[data-testid='projects-btn-new']").click

    assert_current_path new_project_path
    assert_selector "[data-testid='projects-input-name']"
  end

  test "can navigate to new project from switcher dropdown" do
    sign_in_with_form(@owner)

    # Abrir switcher
    find("[data-testid='switcher-btn']").click
    assert_selector "[data-testid='switcher-menu']"

    # Click en nuevo proyecto
    find("[data-testid='switcher-btn-new']").click

    assert_current_path new_project_path
  end

  # =============================================================================
  # Tests: Ver y editar proyecto
  # =============================================================================

  test "owner can view project details" do
    sign_in_with_form(@owner)

    visit projects_path
    find("[data-testid='projects-row-#{@test_project.slug}-btn-view']").click

    assert_current_path project_path(@test_project)
    assert_text @test_project.name
    assert_selector "[data-testid='projects-btn-edit']"
  end

  test "owner can edit their project" do
    sign_in_with_form(@owner)

    visit edit_project_path(@test_project)
    assert_selector "[data-testid='projects-input-name']"

    # Modificar el nombre
    name_input = find("[data-testid='projects-input-name'] input")
    name_input.fill_in with: ""
    name_input.fill_in with: "Proyecto Actualizado"

    find("[data-testid='projects-form-btn-submit']").click

    # Verificar que el proyecto se actualizó (puede redirigir a lista o show)
    assert_text "Proyecto Actualizado"
  end

  # =============================================================================
  # Tests: Eliminar proyecto
  # =============================================================================

  test "owner can delete their project" do
    sign_in_with_form(@owner)

    visit projects_path

    # Click en eliminar
    find("[data-testid='projects-row-#{@test_project.slug}-btn-delete']").click

    # Confirmar en el diálogo
    assert_selector "[data-testid='projects-dialog-delete-btn-confirm']"
    find("[data-testid='projects-dialog-delete-btn-confirm']").click

    # Verificar que el proyecto ya no aparece
    assert_no_text @test_project.name
  end

  private

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end

  def t(key, **options)
    I18n.t(key, scope: :frontend, **options)
  end
end
