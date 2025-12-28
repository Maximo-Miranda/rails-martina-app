<script setup lang="ts">
/**
 * SafeLink - Link wrapper that disables during active requests
 * @example <SafeLink href="/dashboard">Dashboard</SafeLink>
 */
import { computed } from 'vue'
import { Link } from '@inertiajs/vue3'
import type { RequestPayload } from '@inertiajs/core'
import { useGlobalLoading } from '@/composables/useGlobalLoading'

interface Props {
  href: string
  method?: 'get' | 'post' | 'put' | 'patch' | 'delete'
  as?: 'a' | 'button'
  data?: RequestPayload
  headers?: Record<string, string>
  replace?: boolean
  preserveScroll?: boolean | ((page: unknown) => boolean)
  preserveState?: boolean | ((page: unknown) => boolean)
  only?: string[]
  except?: string[]
  disabled?: boolean
  disabledClass?: string
  dataTestId?: string
}

const props = withDefaults(defineProps<Props>(), {
  method: 'get',
  as: 'a',
  replace: false,
  preserveScroll: false,
  preserveState: false,
  disabled: false,
  disabledClass: 'opacity-50 pointer-events-none'
})

const emit = defineEmits<{
  click: [event: MouseEvent]
}>()

const { isLoading } = useGlobalLoading()

const isDisabled = computed(() => props.disabled || isLoading.value)
const disabledClasses = computed(() => isDisabled.value ? props.disabledClass : '')

const handleClick = (event: MouseEvent) => {
  if (isDisabled.value) {
    event.preventDefault()
    event.stopPropagation()
    return
  }
  emit('click', event)
}
</script>

<template>
  <Link
    :href="href"
    :method="method"
    :as="as"
    :data="data"
    :headers="headers"
    :replace="replace"
    :preserve-scroll="preserveScroll"
    :preserve-state="preserveState"
    :only="only"
    :except="except"
    :class="disabledClasses"
    :data-testid="dataTestId"
    :aria-disabled="isDisabled"
    @click="handleClick"
  >
    <slot />
  </Link>
</template>
