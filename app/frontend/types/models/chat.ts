export interface Chat {
  id: number
  title: string
  status: 'active' | 'archived'
  created_at: string
  updated_at: string
}

export interface ChatSummary extends Chat {
  messages_count: number
  last_message_at: string | null
}

export interface Message {
  id: number
  role: 'user_role' | 'assistant_role'
  content: string
  status: 'pending' | 'processing' | 'completed' | 'failed'
  token_count: number | null
  error_message: string | null
  created_at: string
  citations: MessageCitation[]
}

export interface MessageCitation {
  id: number
  document_id: number
  document_name: string | null
  pages: number[] | null
  text_snippet: string | null
  confidence_score: number | null
}

export interface ChatStore {
  id: number
  display_name: string
  status: string
  active_documents_count: number
}

export interface ChatsChannelMessage {
  type: 'new_message' | 'message_created' | 'message_updated' | 'chat_updated' | 'message_failed' | 'sync_response' | 'sync' | 'error'
  chat_id?: number
  message_id?: number
  message?: Message
  chat?: {
    id: number
    title: string
    status?: string
  }
  messages?: Message[]
  citations?: MessageCitation[]
  content?: string
  error_type?: string
}
