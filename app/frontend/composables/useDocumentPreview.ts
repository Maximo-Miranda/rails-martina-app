export type PreviewMode = 'iframe' | 'text' | 'markdown' | 'csv' | 'none'

const PREVIEWABLE_MIME_TYPES: Record<string, PreviewMode> = {
  'application/pdf': 'iframe',
  'text/plain': 'text',
  'text/markdown': 'markdown',
  'text/csv': 'csv',
}

export function useDocumentPreview() {
  function getPreviewMode(contentType: string | null): PreviewMode {
    if (!contentType) return 'none'
    return PREVIEWABLE_MIME_TYPES[contentType] ?? 'none'
  }

  function isPreviewable(contentType: string | null): boolean {
    return getPreviewMode(contentType) !== 'none'
  }

  function needsContentFetch(contentType: string | null): boolean {
    if (!contentType) return false
    const mode = PREVIEWABLE_MIME_TYPES[contentType]
    return mode === 'text' || mode === 'markdown' || mode === 'csv'
  }

  function parseCSV(content: string): string[][] {
    const lines = content.trim().split('\n')
    return lines.map(line => {
      const result: string[] = []
      let current = ''
      let inQuotes = false

      for (const char of line) {
        if (char === '"') {
          inQuotes = !inQuotes
        } else if (char === ',' && !inQuotes) {
          result.push(current.trim())
          current = ''
        } else {
          current += char
        }
      }
      result.push(current.trim())
      return result
    })
  }

  return {
    getPreviewMode,
    isPreviewable,
    needsContentFetch,
    parseCSV,
  }
}
