# frozen_string_literal: true

class CaseDocumentsController < ApplicationController
  before_action :set_legal_case
  before_action :set_case_notebook
  before_action :set_case_document, only: %i[show update destroy enable_ai disable_ai file_url file_content]

  def index
    authorize CaseDocument

    # TODO: Add pagination, sorting, filtering.
    documents = @case_notebook.case_documents.kept.ordered

    render inertia: "CaseDocuments/Index", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      notebook: { id: @case_notebook.id, code: @case_notebook.code },
      documents: documents.map { |d| case_document_json(d) },
      documentTypes: CaseDocument.document_types.keys,
    }
  end

  def show
    authorize @case_document

    render inertia: "CaseDocuments/Show", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      notebook: { id: @case_notebook.id, code: @case_notebook.code },
      document: case_document_detail_json(@case_document),
    }
  end

  def create
    @case_document = @case_notebook.case_documents.build(case_document_params)
    @case_document.uploaded_by = current_user
    authorize @case_document

    if @case_document.save
      redirect_to legal_case_case_notebook_path(@legal_case, @case_notebook), notice: t(".success")
    else
      redirect_to legal_case_case_notebook_path(@legal_case, @case_notebook),
                  inertia: { errors: @case_document.errors }
    end
  end

  # TODO: Implement update in frontend
  def update
    authorize @case_document

    if @case_document.update(case_document_params)
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  notice: t(".success")
    else
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  inertia: { errors: @case_document.errors }
    end
  end

  def destroy
    authorize @case_document

    @case_document.discard
    redirect_to legal_case_case_notebook_path(@legal_case, @case_notebook), notice: t(".success")
  end

  def enable_ai
    authorize @case_document

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: @case_document,
      user: current_user
    )

    if result.success?
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  notice: t(".success")
    else
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  alert: result.error
    end
  end

  def disable_ai
    authorize @case_document

    result = LegalCases::DisableCaseDocumentAiService.call(case_document: @case_document)

    if result.success?
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  notice: t(".success")
    else
      redirect_to legal_case_case_notebook_case_document_path(@legal_case, @case_notebook, @case_document),
                  alert: result.error
    end
  end

  def file_url
    authorize @case_document

    unless @case_document.file.attached?
      return render json: { error: t(".no_file") }, status: :not_found
    end

    url = rails_blob_url(@case_document.file, disposition: "inline")
    render json: { url: url }
  end

  def file_content
    authorize @case_document

    unless @case_document.file.attached?
      return render json: { error: t(".no_file") }, status: :not_found
    end

    content_type = @case_document.file.content_type
    unless content_type.in?(%w[text/plain text/markdown text/csv])
      return render json: { error: "Content not available for this file type" }, status: :unprocessable_entity
    end

    content = @case_document.file.download
    render json: {
      content: content.force_encoding("UTF-8"),
      contentType: content_type,
      filename: @case_document.file.filename.to_s,
    }
  end

  private

  def set_legal_case
    @legal_case = LegalCase.kept.find(params[:legal_case_id])
  end

  def set_case_notebook
    @case_notebook = @legal_case.case_notebooks.kept.find(params[:case_notebook_id])
  end

  def set_case_document
    @case_document = @case_notebook.case_documents.kept.find(params[:id])
  end

  def case_document_params
    params.require(:case_document).permit(
      :document_type, :name, :description, :folio_start, :folio_end,
      :page_count, :document_date, :issuer, :file
    )
  end

  def case_document_json(document)
    {
      id: document.id,
      itemNumber: document.item_number,
      documentType: document.document_type,
      name: document.name,
      foliation: document.foliation,
      documentDate: document.document_date,
      aiEnabled: document.ai_enabled?,
      createdAt: document.created_at,
    }
  end

  def case_document_detail_json(document)
    case_document_json(document).merge(
      description: document.description,
      folioStart: document.folio_start,
      folioEnd: document.folio_end,
      pageCount: document.page_count,
      issuer: document.issuer,
      uploadedById: document.uploaded_by_id,
      hasFile: document.file.attached?,
      contentType: document.file.attached? ? document.file.content_type : nil
    )
  end
end
