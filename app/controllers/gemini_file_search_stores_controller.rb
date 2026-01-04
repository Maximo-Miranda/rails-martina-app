# frozen_string_literal: true

class GeminiFileSearchStoresController < ApplicationController
  include RansackPagyIndex

  around_action :skip_tenant_scoping
  before_action :set_store, only: %i[show edit update destroy]

  def index
    authorize GeminiFileSearchStore

    @q, filters = build_ransack(
      policy_scope(GeminiFileSearchStore).where.not(status: :deleted),
      allowed_q_keys: %i[display_name_or_gemini_store_name_cont status_eq],
      allowed_sort_fields: %w[display_name status created_at],
      default_sort: "created_at desc"
    )

    @pagy, stores = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    stores_json = stores.map do |store|
      store.as_json(only: %i[id display_name gemini_store_name status error_message active_documents_count size_bytes created_at])
    end

    render inertia: "GeminiFileSearchStores/Index", props: {
      stores: stores_json,
      pagination: pagy_pagination(@pagy),
      filters: filters,
    }
  end

  def show
    authorize @store
    render inertia: "GeminiFileSearchStores/Show", props: {
      store: @store.as_json(only: %i[id display_name gemini_store_name status error_message active_documents_count size_bytes metadata created_at updated_at]),
    }
  end

  def new
    @store = GeminiFileSearchStore.new
    authorize @store
    render inertia: "GeminiFileSearchStores/Form", props: {
      store: @store.as_json(only: %i[id display_name]),
    }
  end

  def create
    @store = GeminiFileSearchStore.new(store_params)
    @store.project_id = nil
    authorize @store

    if @store.save
      Rails.configuration.event_store.publish(
        Gemini::StoreCreationRequested.new(data: {
          store_id: @store.id,
          project_id: nil,
          display_name: @store.display_name,
          user_id: current_user.id,
        }),
        stream_name: "GeminiFileSearchStore$#{@store.id}"
      )

      redirect_to gemini_file_search_stores_path, notice: I18n.t("gemini_stores.created")
    else
      render inertia: "GeminiFileSearchStores/Form", props: {
        store: @store.as_json(only: %i[id display_name]),
        errors: @store.errors.as_json,
      }
    end
  end

  def edit
    authorize @store
    render inertia: "GeminiFileSearchStores/Form", props: {
      store: @store.as_json(only: %i[id display_name gemini_store_name status]),
    }
  end

  def update
    authorize @store

    if @store.update(store_params)
      redirect_to gemini_file_search_stores_path, notice: I18n.t("gemini_stores.updated")
    else
      render inertia: "GeminiFileSearchStores/Form", props: {
        store: @store.as_json(only: %i[id display_name gemini_store_name status]),
        errors: @store.errors.as_json,
      }
    end
  end

  def destroy
    authorize @store

    # Optimistic update: mark as deleted immediately so it disappears from the list
    @store.update(status: :deleted)

    Rails.configuration.event_store.publish(
      Gemini::StoreDeletionRequested.new(data: {
        store_id: @store.id,
        project_id: nil,
        gemini_store_name: @store.gemini_store_name,
        user_id: current_user.id,
      }),
      stream_name: "GeminiFileSearchStore$#{@store.id}"
    )

    redirect_to gemini_file_search_stores_path, notice: I18n.t("gemini_stores.deleted")
  end

  private

  def set_store
    @store = GeminiFileSearchStore.find(params[:id])
  end

  # Override from ApplicationController to bypass project requirement
  def creating_project?
    true
  end

  # Override from ApplicationController to disable automatic tenant scoping
  def set_tenant_for_request?
    false
  end

  def skip_tenant_scoping(&block)
    ActsAsTenant.without_tenant(&block)
  end

  def store_params
    params.require(:gemini_file_search_store).permit(:display_name)
  end
end
