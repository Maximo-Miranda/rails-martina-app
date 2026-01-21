# frozen_string_literal: true

class CaseNotebooksController < ApplicationController
  before_action :set_legal_case
  before_action :set_case_notebook, only: %i[show update destroy]

  def index
    authorize CaseNotebook

    # TODO: Add pagination, sorting, filtering, etc.
    notebooks = @legal_case.case_notebooks.kept.ordered

    render inertia: "CaseNotebooks/Index", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      notebooks: notebooks.map { |n| case_notebook_json(n) },
      notebookTypes: CaseNotebook.notebook_types.keys,
    }
  end

  def new
    @case_notebook = @legal_case.case_notebooks.build
    authorize @case_notebook

    render inertia: "CaseNotebooks/Form", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      notebook: {},
      notebookTypes: CaseNotebook.notebook_types.keys,
    }
  end

  def show
    authorize @case_notebook

    documents = @case_notebook.case_documents.kept.ordered

    render inertia: "CaseNotebooks/Show", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      notebook: case_notebook_json(@case_notebook),
      documents: documents.map { |d| case_document_json(d) },
    }
  end

  def create
    @case_notebook = @legal_case.case_notebooks.build(case_notebook_params)
    authorize @case_notebook

    if @case_notebook.save
      redirect_to legal_case_path(@legal_case, tab: "notebooks"), notice: t(".success")
    else
      render inertia: "CaseNotebooks/Form", props: {
        legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
        notebook: case_notebook_form_json(@case_notebook),
        notebookTypes: CaseNotebook.notebook_types.keys,
        errors: @case_notebook.errors,
      }
    end
  end

  def update
    authorize @case_notebook

    if @case_notebook.update(case_notebook_params)
      redirect_to legal_case_case_notebook_path(@legal_case, @case_notebook), notice: t(".success")
    else
      render inertia: "CaseNotebooks/Form", props: {
        legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
        notebook: case_notebook_form_json(@case_notebook),
        notebookTypes: CaseNotebook.notebook_types.keys,
        errors: @case_notebook.errors,
      }
    end
  end

  def destroy
    authorize @case_notebook

    @case_notebook.discard
    redirect_to legal_case_path(@legal_case, tab: "notebooks"), notice: t(".success")
  end

  private

  def set_legal_case
    @legal_case = LegalCase.kept.find(params[:legal_case_id])
  end

  def set_case_notebook
    @case_notebook = @legal_case.case_notebooks.kept.find(params[:id])
  end

  def case_notebook_params
    params.require(:case_notebook).permit(:notebook_type, :code, :description, :volume)
  end

  def case_notebook_json(notebook)
    {
      id: notebook.id,
      notebookType: notebook.notebook_type,
      code: notebook.code,
      description: notebook.description,
      volume: notebook.volume,
      folioCount: notebook.folio_count,
      documentsCount: notebook.case_documents.kept.count,
      createdAt: notebook.created_at,
    }
  end

  def case_notebook_form_json(notebook)
    {
      id: notebook.id,
      notebookType: notebook.notebook_type,
      code: notebook.code,
      description: notebook.description,
      volume: notebook.volume,
    }
  end

  def case_document_json(document)
    {
      id: document.id,
      itemNumber: document.item_number,
      documentType: document.document_type,
      name: document.name,
      description: document.description,
      foliation: document.foliation,
      documentDate: document.document_date,
      issuer: document.issuer,
      aiEnabled: document.ai_enabled?,
      createdAt: document.created_at,
    }
  end
end
