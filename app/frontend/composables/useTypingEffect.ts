import { ref, watch, onUnmounted } from 'vue'

interface UseTypingEffectOptions {
  speed?: number
  enabled?: boolean
  onComplete?: () => void
}

export function useTypingEffect(
  content: () => string,
  options: UseTypingEffectOptions = {}
) {
  const { speed = 50, enabled = true, onComplete } = options

  const displayedContent = ref('')
  const isTyping = ref(false)
  let intervalId: ReturnType<typeof setInterval> | null = null
  let currentIndex = 0

  const clearTypingInterval = () => {
    if (intervalId) {
      clearInterval(intervalId)
      intervalId = null
    }
  }

  const getCharDelay = (char: string, baseInterval: number): number => {
    if (['.', '!', '?', ':'].includes(char)) return baseInterval * 4
    if ([',', ';'].includes(char)) return baseInterval * 2
    if (char === '\n') return baseInterval * 3
    return baseInterval
  }

  const startTyping = (fullContent: string) => {
    clearTypingInterval()

    if (!enabled || !fullContent) {
      displayedContent.value = fullContent
      isTyping.value = false
      return
    }

    if (displayedContent.value === fullContent) {
      isTyping.value = false
      return
    }

    currentIndex = 0
    displayedContent.value = ''
    isTyping.value = true

    const intervalMs = 1000 / speed

    const typeNextChunk = () => {
      if (currentIndex >= fullContent.length) {
        clearTypingInterval()
        isTyping.value = false
        onComplete?.()
        return
      }

      const chunkSize = Math.min(3, fullContent.length - currentIndex)
      displayedContent.value = fullContent.slice(0, currentIndex + chunkSize)
      currentIndex += chunkSize

      const lastChar = fullContent[currentIndex - 1]
      clearTypingInterval()
      intervalId = setTimeout(typeNextChunk, getCharDelay(lastChar, intervalMs))
    }

    typeNextChunk()
  }

  const skipToEnd = () => {
    clearTypingInterval()
    displayedContent.value = content()
    isTyping.value = false
  }

  watch(content, (newContent) => {
    if (newContent) startTyping(newContent)
  }, { immediate: true })

  onUnmounted(clearTypingInterval)

  return { displayedContent, isTyping, skipToEnd }
}
