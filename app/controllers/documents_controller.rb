# frozen_string_literal: true

class DocumentsController < ApplicationController
  include RansackPagyIndex

  around_action :skip_tenant_scoping, if: :global_scope?
  before_action :set_document, only: %i[show destroy]
  before_action :set_store, only: %i[new create]
  before_action :set_store_or_redirect, only: %i[index]

  def index
    authorize authorization_record, :index?

    if global_scope? && @store.nil?
      stores = GeminiFileSearchStore.kept.global.where(status: :active).order(:display_name)
      return render inertia: "Documents/SelectStore", props: {
        stores: stores.map { |s| store_json(s) },
      }
    end

    base_scope = policy_scope(Document).for_store(@store).kept.where.not(status: :deleted)
    scoped_documents = global_scope? ? base_scope.global : base_scope

    @q, filters = build_ransack(
      scoped_documents,
      allowed_q_keys: %i[display_name_cont content_type_eq status_eq],
      allowed_sort_fields: %w[display_name content_type status created_at size_bytes],
      default_sort: "created_at desc"
    )

    @pagy, documents = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    render inertia: "Documents/Index", props: {
      project: global_scope? ? nil : project_json(current_project),
      documents: documents_json(documents),
      store: store_json(@store),
      pagination: pagy_pagination(@pagy),
      filters: filters,
      supportedContentTypes: Document::SUPPORTED_CONTENT_TYPES.keys,
      maxFileSize: Document::MAX_FILE_SIZE,
      canCreateDocument: policy(authorization_record).create?,
      canDeleteDocument: policy(authorization_record).destroy?,
    }
  end

  def show
    authorize @document

    render inertia: "Documents/Show", props: {
      project: global_scope? ? nil : project_json(current_project),
      document: document_json(@document),
      store: store_json(@document.gemini_file_search_store),
    }
  end

  def new
    @document = if global_scope?
                  Document.new(gemini_file_search_store: @store, project_id: nil)
    else
                  Document.new(gemini_file_search_store: @store)
    end
    authorize @document

    render inertia: "Documents/Form", props: {
      project: global_scope? ? nil : project_json(current_project),
      document: {
        gemini_file_search_store_id: @store.id,
        project_id: global_scope? ? nil : current_project.id,
      },
      store: store_json(@store),
      supportedContentTypes: Document::SUPPORTED_CONTENT_TYPES.keys,
      maxFileSize: Document::MAX_FILE_SIZE,
    }
  end

  def create
    @document = Document.new(document_params)
    @document.gemini_file_search_store = @store
    @document.project_id = nil if global_scope?
    @document.uploaded_by = current_user
    authorize @document

    if @document.save
      publish_upload_event(@document)
      redirect_to documents_path(store_id: global_scope? ? @store.id : nil, scope: params[:scope]),
                  notice: I18n.t("documents.created")
    else
      render inertia: "Documents/Form", props: {
        project: global_scope? ? nil : project_json(current_project),
        document: @document.as_json(only: %i[display_name custom_metadata]),
        store: store_json(@store),
        errors: @document.errors.as_json,
        supportedContentTypes: Document::SUPPORTED_CONTENT_TYPES.keys,
        maxFileSize: Document::MAX_FILE_SIZE,
      }
    end
  end

  def destroy
    authorize @document

    @document.discard

    is_global = @document.project_id.nil?
    redirect_to documents_path(
      store_id: is_global ? @document.gemini_file_search_store_id : nil,
      scope: is_global ? "global" : nil
    ), notice: I18n.t("documents.deleted")
  end

  private

  def set_document
    @document = if global_scope?
                  Document.global.kept.find(params[:id])
    else
                  current_project.documents.kept.find(params[:id])
    end
  end

  def set_store
    if global_scope?
      @store = GeminiFileSearchStore.find(params[:store_id])
    else
      @store = current_project.gemini_file_search_store

      return if @store

      redirect_to new_gemini_file_search_store_path(project_id: current_project.id),
                  alert: I18n.t("documents.no_store_for_project")
    end
  end

  def set_store_or_redirect
    if global_scope?
      @store = GeminiFileSearchStore.kept.global.find_by(id: params[:store_id], status: :active) if params[:store_id].present?
    else
      @store = current_project.gemini_file_search_store

      return if @store

      redirect_to new_gemini_file_search_store_path(project_id: current_project.id),
                  alert: I18n.t("documents.no_store_for_project")
    end
  end

  def global_scope?
    params[:scope] == "global"
  end

  def document_params
    params.require(:document).permit(:display_name, :file, custom_metadata: {})
  end

  def publish_upload_event(document)
    Rails.configuration.event_store.publish(
      Documents::UploadRequested.new(data: {
        document_id: document.id,
        store_id: document.gemini_file_search_store_id,
        user_id: current_user.id,
        display_name: document.display_name,
      }),
      stream_name: "Document$#{document.id}"
    )
  end

  def creating_project?
    global_scope? ? true : super
  end

  def set_tenant_for_request?
    global_scope? ? false : super
  end

  def skip_tenant_scoping(&block)
    ActsAsTenant.without_tenant(&block)
  end

  def authorization_record
    if global_scope?
      Document.new(project_id: nil)
    else
      Document.new
    end
  end

  def documents_json(documents)
    documents.map { |doc| document_json(doc) }
  end

  def document_json(doc)
    doc.as_json(only: %i[
      id display_name content_type size_bytes file_hash status
      remote_id gemini_document_path custom_metadata error_message
      created_at updated_at
    ]).merge(
      uploaded_by: doc.uploaded_by.as_json(only: %i[id full_name email]),
      file_url: doc.file.attached? ? url_for(doc.file) : nil
    )
  end

  def project_json(project)
    project.as_json(only: %i[id name slug])
  end

  def store_json(store)
    store.as_json(only: %i[id display_name gemini_store_name status size_bytes active_documents_count])
         .merge(available_bytes: Document::MAX_STORE_SIZE - store.size_bytes)
  end
end
