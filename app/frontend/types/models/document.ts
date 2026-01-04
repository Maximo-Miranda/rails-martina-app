export interface Document {
  id: number
  display_name: string
  content_type: string
  size_bytes: number
  file_hash: string
  status: 'pending' | 'synced' | 'failed' | 'deleted'
  remote_id: string | null
  gemini_document_path: string | null
  custom_metadata: DocumentMetadata | null
  error_message: string | null
  created_at: string
  updated_at: string
  uploaded_by: {
    id: number
    full_name: string
    email: string
  }
  file_url: string | null
}

export interface DocumentMetadata {
  chat_correlation_id?: string
  context_tags?: string[]
  source_url?: string
  [key: string]: unknown
}

export interface GeminiStore {
  id: number
  display_name: string
  gemini_store_name: string | null
  status: string
  size_bytes: number
  active_documents_count: number
  available_bytes: number
}

export interface DocumentFormData {
  display_name: string
  file: File | null
  custom_metadata: DocumentMetadata
  gemini_file_search_store_id: number
  project_id?: number | null
}
