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

  test "super_admin can see all projects in the list" do
    sign_in_with_form(@super_admin)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    assert_text @test_project.name
    assert_text @other_project.name
  end

  test "admin can see all projects in the list" do
    sign_in_with_form(@admin)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    assert_text @test_project.name
    assert_text @other_project.name
  end

  test "owner can see only their accessible projects" do
    sign_in_with_form(@owner)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    assert_text @test_project.name
    assert_text @other_project.name
  end

  test "coworker can see only projects where they have a role" do
    sign_in_with_form(@coworker)

    visit projects_path
    assert_selector "[data-testid='projects-table']"

    assert_text @test_project.name
    assert_no_text @other_project.name
  end

  test "super_admin can see all projects in the switcher dropdown" do
    sign_in_with_form(@super_admin)

    find("[data-testid='switcher-btn']").click
    assert_selector "[data-testid='switcher-menu']"

    assert_selector "[data-testid='switcher-project-#{@test_project.slug}']"
    assert_selector "[data-testid='switcher-project-#{@other_project.slug}']"
  end

  test "owner can switch projects using the switcher" do
    sign_in_with_form(@owner)

    assert_selector "[data-testid='switcher-btn']"

    find("[data-testid='switcher-btn']").click
    assert_selector "[data-testid='switcher-menu']"

    find("[data-testid='switcher-project-#{@other_project.slug}']").click

    assert_current_path dashboard_path

    assert_text @other_project.name
  end

  test "authenticated user can create a new project" do
    sign_in_with_form(@owner)

    visit new_project_path
    assert_selector "[data-testid='projects-input-name']"

    fill_in_field "[data-testid='projects-input-name'] input", with: "Mi Nuevo Proyecto"
    fill_in_field "[data-testid='projects-input-description'] textarea", with: "Descripción del proyecto de prueba"

    find("[data-testid='projects-form-btn-submit']").click

    assert_current_path dashboard_path

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

    name_input = find("[data-testid='projects-input-name'] input")
    name_input.fill_in with: ""
    name_input.fill_in with: "Proyecto Actualizado"

    find("[data-testid='projects-form-btn-submit']").click

    assert_text "Proyecto Actualizado"
  end

  test "owner can delete their project" do
    sign_in_with_form(@owner)

    visit projects_path

    find("[data-testid='projects-row-#{@test_project.slug}-btn-delete']").click

    assert_selector "[data-testid='projects-dialog-delete-btn-confirm']"
    find("[data-testid='projects-dialog-delete-btn-confirm']").click

    assert_no_text @test_project.name
  end

  test "coworker cannot edit project where they are not owner" do
    sign_in_with_form(@coworker)

    visit project_path(@test_project)

    assert_no_selector "[data-testid='projects-btn-edit']"
  end

  test "coworker cannot delete project where they are not owner" do
    sign_in_with_form(@coworker)

    visit projects_path

    assert_no_selector "[data-testid='projects-row-#{@test_project.slug}-btn-delete']"
  end

  test "client cannot edit project where they are not owner" do
    client = users(:client_user)
    sign_in_with_form(client)

    visit project_path(@test_project)

    assert_no_selector "[data-testid='projects-btn-edit']"
  end

  test "client cannot delete project where they are not owner" do
    client = users(:client_user)
    sign_in_with_form(client)

    visit projects_path

    assert_no_selector "[data-testid='projects-row-#{@test_project.slug}-btn-delete']"
  end

  private

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end

  def t(key, **options)
    I18n.t(key, scope: :frontend, **options)
  end
end
