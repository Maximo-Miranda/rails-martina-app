import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import { aliases, mdi } from 'vuetify/iconsets/mdi'
import '@mdi/font/css/materialdesignicons.css'

export default createVuetify({
  components,
  directives,
  icons: {
    defaultSet: 'mdi',
    aliases,
    sets: {
      mdi,
    },
  },
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        dark: false,
        colors: {
          primary: '#1867C0',
          'primary-darken-1': '#1456A0',
          secondary: '#5CBBF6',
          'secondary-darken-1': '#4A9DD4',
          accent: '#9C27B0',
          error: '#F44336',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
          background: '#FAFAFA',
          surface: '#FFFFFF',
          'surface-variant': '#F5F5F5',
          'on-surface-variant': '#424242',
        },
      },
      dark: {
        dark: true,
        colors: {
          primary: '#2196F3',
          'primary-darken-1': '#1976D2',
          secondary: '#03DAC6',
          'secondary-darken-1': '#018786',
          accent: '#BB86FC',
          error: '#CF6679',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FB8C00',
          background: '#121212',
          surface: '#1E1E1E',
          'surface-variant': '#2D2D2D',
          'on-surface-variant': '#BDBDBD',
        },
      },
    },
  },
  defaults: {
    VBtn: {
      variant: 'flat',
      rounded: 'lg',
    },
    VCard: {
      rounded: 'lg',
    },
    VTextField: {
      variant: 'outlined',
      density: 'comfortable',
    },
    VSelect: {
      variant: 'outlined',
      density: 'comfortable',
    },
  },
})