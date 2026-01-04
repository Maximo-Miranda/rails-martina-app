/**
 * Composable for formatting file-related data (content types, sizes, etc.)
 * Only includes document types supported by Gemini File Search API
 */
export function useFileFormat() {
  const mimeToLabel: Record<string, string> = {
    'application/pdf': 'PDF',
    'application/msword': 'DOC',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'DOCX',
    'application/vnd.ms-excel': 'XLS',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'XLSX',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'PPTX',
    'application/vnd.oasis.opendocument.text': 'ODT',
    'text/plain': 'TXT',
    'text/markdown': 'MD',
    'text/csv': 'CSV',
  }

  /**
   * Converts a MIME type to a human-readable label
   */
  function formatContentType(contentType: string): string {
    return mimeToLabel[contentType] || contentType.split('/').pop()?.toUpperCase() || contentType
  }

  /**
   * Returns an appropriate Material Design icon for a content type
   * Only includes icons for supported document types
   */
  function getContentTypeIcon(contentType: string): string {
    if (contentType.includes('pdf')) return 'mdi-file-pdf-box'
    if (contentType.includes('word') || contentType.includes('wordprocessingml')) return 'mdi-file-word'
    if (contentType.includes('excel') || contentType.includes('spreadsheet')) return 'mdi-file-excel'
    if (contentType.includes('presentation') || contentType.includes('powerpoint')) return 'mdi-file-powerpoint'
    if (contentType.includes('opendocument.text')) return 'mdi-file-document'
    if (contentType.includes('text/plain')) return 'mdi-file-document-outline'
    if (contentType.includes('markdown')) return 'mdi-markdown'
    if (contentType.includes('csv')) return 'mdi-file-delimited'
    return 'mdi-file-document'
  }

  /**
   * Formats bytes to a human-readable string (e.g., "1.5 MB")
   */
  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B'
    const k = 1024
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
  }

  return {
    formatContentType,
    getContentTypeIcon,
    formatBytes,
  }
}
