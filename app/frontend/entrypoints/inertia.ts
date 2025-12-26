import { createInertiaApp, router } from '@inertiajs/vue3'
import { createApp, DefineComponent, h } from 'vue'
import vuetify from '../plugins/vuetify'
import AppLayout from '../layouts/AppLayout.vue'
import AuthLayout from '../layouts/AuthLayout.vue'

// Handle invalid responses (non-Inertia responses) as a defensive fallback.
// This typically happens when session expires and the server returns a login page
// instead of an Inertia response. Force a full page reload in such cases.
router.on('invalid', (event) => {
  // Prevent the default modal dialog from showing
  event.preventDefault()

  // Force a full page reload to the current URL
  // The server will redirect to login if needed
  window.location.reload()
})

createInertiaApp({
  // Set default page title
  // see https://inertia-rails.dev/guide/title-and-meta
  title: title => title ? `${title} - Martina` : 'Martina',

  // Disable progress bar
  //
  // see https://inertia-rails.dev/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob<DefineComponent>('../pages/**/*.vue', {
      eager: true,
    })
    const page = pages[`../pages/${name}.vue`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.vue'`)
    }

    // Assign layout based on page path
    // Auth pages (login, register) use AuthLayout
    // All other pages use AppLayout
    if (page?.default) {
      if (name.startsWith('auth/')) {
        page.default.layout = page.default.layout || AuthLayout
      } else {
        page.default.layout = page.default.layout || AppLayout
      }
    }

    return page
  },

  setup({ el, App, props, plugin }) {
    createApp({ render: () => h(App, props) })
      .use(plugin)
      .use(vuetify)
      .mount(el)
  },

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
    },
    future: {
      useScriptElementForInitialPage: true,
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      preserveEqualProps: true,
    },
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error
  } else {
    console.error(
      "Missing root element.\n\n" +
      "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
      'Consider moving <%= vite_javascript_tag "inertia" %> to the Inertia-specific layout instead.',
    )
  }
})

