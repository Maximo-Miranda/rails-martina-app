<!-- filepath: app/frontend/pages/layouts/AppLayout.vue -->
<template>
  <v-app>
    <v-app-bar color="primary">
      <v-app-bar-title>Martina App</v-app-bar-title>
    </v-app-bar>

    <v-main>
      <v-container>
        <slot />
      </v-container>
    </v-main>
  </v-app>
</template>