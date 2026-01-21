export type LegalCaseStatus = 'activo' | 'archivado' | 'terminado' | 'suspendido'

export type LegalCaseSpecialty =
  | 'civil'
  | 'penal'
  | 'laboral'
  | 'familia'
  | 'administrativo'
  | 'constitucional'
  | 'comercial'
  | 'tributario'
  | 'otro'

export interface LegalCase {
  id: number
  caseNumber: string
  court: string
  specialty: LegalCaseSpecialty
  status: LegalCaseStatus
  actionType: string
  plaintiff: string
  defendant: string
  filingDate: string
  currentTermDate: string | null
  createdAt: string
}

export interface LegalCaseDetail extends LegalCase {
  plaintiffLawyer: string | null
  defendantLawyer: string | null
  lawyerInCharge: string
  lawyerPhone: string | null
  lawyerEmail: string | null
  lawyerProfessionalCard: string | null
  lastActionDate: string | null
  notes: string | null
  createdById: number
}

export interface LegalCaseFormData {
  case_number: string
  court: string
  specialty: LegalCaseSpecialty
  status: LegalCaseStatus
  action_type: string
  filing_date: string
  plaintiff: string
  defendant: string
  plaintiff_lawyer?: string
  defendant_lawyer?: string
  lawyer_in_charge: string
  lawyer_phone?: string
  lawyer_email?: string
  lawyer_professional_card?: string
  current_term_date?: string
  last_action_date?: string
  notes?: string
}

export type NotebookType =
  | 'principal'
  | 'medidas_cautelares'
  | 'ejecucion'
  | 'incidentes'
  | 'apelacion'
  | 'casacion'
  | 'otro'

export interface CaseNotebook {
  id: number
  notebookType: NotebookType
  code: string
  description: string | null
  volume: number
  folioCount: number
  documentsCount: number
  createdAt?: string
}

export type CaseDocumentType =
  | 'demanda'
  | 'contestacion'
  | 'auto'
  | 'sentencia'
  | 'recurso'
  | 'memorial'
  | 'prueba'
  | 'notificacion'
  | 'poder'
  | 'dictamen'
  | 'acta'
  | 'otro'

export interface CaseDocument {
  id: number
  itemNumber: number
  documentType: CaseDocumentType
  name: string
  foliation: string | null
  documentDate: string | null
  aiEnabled: boolean
  createdAt: string
}

// Alias for list views
export type CaseDocumentItem = CaseDocument

export interface CaseDocumentDetail extends CaseDocument {
  description: string | null
  folioStart: number | null
  folioEnd: number | null
  pageCount: number | null
  issuer: string | null
  uploadedById: number
  hasFile: boolean
  contentType: string | null
}

export type CourtOrderType =
  | 'auto_interlocutorio'
  | 'auto_de_tramite'
  | 'sentencia'
  | 'providencia'
  | 'resolucion'
  | 'otro'

export type CourtOrderStatus = 'pendiente' | 'cumplido' | 'vencido' | 'en_apelacion'

export interface CourtOrder {
  id: number
  orderType: CourtOrderType
  summary: string | null
  orderDate: string
  deadline: string | null
  status: CourtOrderStatus
  overdue: boolean
  daysUntilDeadline: number | null
  createdAt: string
}

export interface CourtOrderDetail extends CourtOrder {
  createdById: number
}

export type CaseReminderType =
  | 'audiencia'
  | 'vencimiento_termino'
  | 'presentar_memorial'
  | 'revision_expediente'
  | 'pago_arancel'
  | 'cita_cliente'
  | 'otro'

export interface CaseReminder {
  id: number
  title: string
  reminderType: CaseReminderType
  displayType: string
  reminderAt: string
  location: string | null
  acknowledged: boolean
  createdAt: string
}

export interface CaseReminderDetail extends CaseReminder {
  description: string | null
  customType: string | null
  courtOrderId: number | null
  createdById: number
}

export interface CaseReminderUser {
  id: number
  userId: number
  userName: string
  acknowledged: boolean
  acknowledgedAt: string | null
}
