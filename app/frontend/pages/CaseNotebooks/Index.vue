<script setup lang="ts">
import { ref } from "vue";
import { router } from "@inertiajs/vue3";
import { useTranslations } from "@/composables/useTranslations";
import { useNavigation } from "@/composables/useNavigation";
import PageHeader from "@/components/PageHeader.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import type { CaseNotebook } from "@/types";

interface LegalCaseRef {
    id: number;
    caseNumber: string;
}

const props = defineProps<{
    legalCase: LegalCaseRef;
    notebooks: CaseNotebook[];
    notebookTypes: string[];
}>();

const { t } = useTranslations();
const { navigateTo } = useNavigation();

const showFormDialog = ref(false);
const editingNotebook = ref<CaseNotebook | null>(null);
const deleteDialog = ref(false);
const deleteTargetId = ref<number | null>(null);
const deleting = ref(false);
const saving = ref(false);

const form = ref({
    notebook_type: "principal",
    code: "",
    description: "",
    volume: 1,
});

const errors = ref<Record<string, string[]>>({});

const openNewForm = () => {
    editingNotebook.value = null;
    form.value = {
        notebook_type: "principal",
        code: "",
        description: "",
        volume: 1,
    };
    errors.value = {};
    showFormDialog.value = true;
};

const openEditForm = (notebook: CaseNotebook) => {
    editingNotebook.value = notebook;
    form.value = {
        notebook_type: notebook.notebookType,
        code: notebook.code,
        description: notebook.description || "",
        volume: notebook.volume,
    };
    errors.value = {};
    showFormDialog.value = true;
};

const submitForm = () => {
    saving.value = true;

    if (editingNotebook.value) {
        router.put(
            `/legal_cases/${props.legalCase.id}/case_notebooks/${editingNotebook.value.id}`,
            { case_notebook: form.value },
            {
                onSuccess: () => {
                    showFormDialog.value = false;
                    saving.value = false;
                },
                onError: (e) => {
                    errors.value = e as Record<string, string[]>;
                    saving.value = false;
                },
            },
        );
    } else {
        router.post(
            `/legal_cases/${props.legalCase.id}/case_notebooks`,
            { case_notebook: form.value },
            {
                onSuccess: () => {
                    showFormDialog.value = false;
                    saving.value = false;
                },
                onError: (e) => {
                    errors.value = e as Record<string, string[]>;
                    saving.value = false;
                },
            },
        );
    }
};

const confirmDelete = (id: number) => {
    deleteTargetId.value = id;
    deleteDialog.value = true;
};

const deleteNotebook = () => {
    if (!deleteTargetId.value) return;
    deleting.value = true;

    router.delete(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${deleteTargetId.value}`,
        {
            onFinish: () => {
                deleting.value = false;
                deleteDialog.value = false;
                deleteTargetId.value = null;
            },
        },
    );
};

const goToNotebook = (notebook: CaseNotebook) => {
    navigateTo(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${notebook.id}`,
    );
};

const goBack = () => {
    navigateTo(`/legal_cases/${props.legalCase.id}?tab=notebooks`);
};
</script>

<template>
    <v-container class="py-6">
        <PageHeader
            :title="t('case_notebooks.title')"
            :subtitle="legalCase.caseNumber"
        >
            <template #actions>
                <v-btn
                    variant="outlined"
                    size="small"
                    prepend-icon="mdi-arrow-left"
                    data-testid="case-notebooks-btn-back"
                    @click="goBack"
                >
                    {{ t("common.back") }}
                </v-btn>
                <v-btn
                    color="primary"
                    size="small"
                    prepend-icon="mdi-plus"
                    data-testid="case-notebooks-btn-new"
                    @click="openNewForm"
                >
                    {{ t("case_notebooks.new") }}
                </v-btn>
            </template>
        </PageHeader>

        <v-card class="rounded-xl" elevation="0" border>
            <v-list v-if="notebooks.length > 0" lines="two">
                <v-list-item
                    v-for="notebook in notebooks"
                    :key="notebook.id"
                    :data-testid="`case-notebook-item-${notebook.id}`"
                    @click="goToNotebook(notebook)"
                >
                    <template #prepend>
                        <v-icon color="primary">mdi-folder</v-icon>
                    </template>

                    <v-list-item-title class="font-weight-medium">
                        {{ notebook.code }} -
                        {{
                            t(
                                `legal_cases.notebook_types.${notebook.notebookType}`,
                            )
                        }}
                    </v-list-item-title>
                    <v-list-item-subtitle>
                        <span v-if="notebook.description"
                            >{{ notebook.description }} •
                        </span>
                        {{ notebook.documentsCount }}
                        {{ t("legal_cases.documents") }} •
                        {{ notebook.folioCount }} {{ t("legal_cases.folios") }}
                    </v-list-item-subtitle>

                    <template #append>
                        <v-chip size="small" variant="tonal" class="mr-2">
                            {{ t("legal_cases.volume") }} {{ notebook.volume }}
                        </v-chip>
                        <v-tooltip location="top" :text="t('tooltips.edit')">
                            <template #activator="{ props: tooltipProps }">
                                <v-btn
                                    v-bind="tooltipProps"
                                    icon
                                    variant="text"
                                    size="small"
                                    :data-testid="`case-notebook-btn-edit-${notebook.id}`"
                                    @click.stop="openEditForm(notebook)"
                                >
                                    <v-icon>mdi-pencil</v-icon>
                                </v-btn>
                            </template>
                        </v-tooltip>
                        <v-tooltip location="top" :text="t('tooltips.delete')">
                            <template #activator="{ props: tooltipProps }">
                                <v-btn
                                    v-bind="tooltipProps"
                                    icon
                                    variant="text"
                                    size="small"
                                    color="error"
                                    :data-testid="`case-notebook-btn-delete-${notebook.id}`"
                                    @click.stop="confirmDelete(notebook.id)"
                                >
                                    <v-icon>mdi-delete</v-icon>
                                </v-btn>
                            </template>
                        </v-tooltip>
                    </template>
                </v-list-item>
            </v-list>

            <v-card-text v-else class="text-center py-8">
                <v-icon size="64" color="grey-lighten-1" class="mb-4"
                    >mdi-folder-open-outline</v-icon
                >
                <p class="text-grey">{{ t("legal_cases.no_notebooks") }}</p>
                <v-btn
                    color="primary"
                    variant="tonal"
                    class="mt-4"
                    prepend-icon="mdi-plus"
                    data-testid="case-notebooks-btn-new-empty"
                    @click="openNewForm"
                >
                    {{ t("case_notebooks.new") }}
                </v-btn>
            </v-card-text>
        </v-card>

        <!-- Form Dialog -->
        <v-dialog v-model="showFormDialog" max-width="600" persistent>
            <v-card>
                <v-card-title class="d-flex align-center">
                    <v-icon class="mr-2">mdi-folder</v-icon>
                    {{
                        editingNotebook
                            ? t("case_notebooks.edit")
                            : t("case_notebooks.new")
                    }}
                </v-card-title>

                <v-card-text>
                    <v-form @submit.prevent="submitForm">
                        <v-select
                            v-model="form.notebook_type"
                            :items="notebookTypes"
                            :label="t('case_notebooks.notebook_type')"
                            :error-messages="errors.notebook_type"
                            data-testid="case-notebook-input-type"
                            required
                        >
                            <template #item="{ props: itemProps, item }">
                                <v-list-item
                                    v-bind="itemProps"
                                    :title="
                                        t(
                                            `legal_cases.notebook_types.${item.raw}`,
                                        )
                                    "
                                >
                                </v-list-item>
                            </template>
                            <template #selection="{ item }">
                                {{
                                    t(`legal_cases.notebook_types.${item.raw}`)
                                }}
                            </template>
                        </v-select>

                        <v-text-field
                            v-model="form.code"
                            :label="t('case_notebooks.code')"
                            :error-messages="errors.code"
                            data-testid="case-notebook-input-code"
                            required
                            class="mt-4"
                        />

                        <v-textarea
                            v-model="form.description"
                            :label="t('case_notebooks.description')"
                            :error-messages="errors.description"
                            data-testid="case-notebook-input-description"
                            rows="3"
                            class="mt-4"
                        />

                        <v-text-field
                            v-model.number="form.volume"
                            :label="t('case_notebooks.volume')"
                            :error-messages="errors.volume"
                            data-testid="case-notebook-input-volume"
                            type="number"
                            min="1"
                            class="mt-4"
                        />
                    </v-form>
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn
                        variant="text"
                        :disabled="saving"
                        data-testid="case-notebook-btn-cancel"
                        @click="showFormDialog = false"
                    >
                        {{ t("common.cancel") }}
                    </v-btn>
                    <v-btn
                        color="primary"
                        :loading="saving"
                        data-testid="case-notebook-btn-submit"
                        @click="submitForm"
                    >
                        {{
                            editingNotebook
                                ? t("common.save")
                                : t("common.create")
                        }}
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Delete Confirmation -->
        <ConfirmDialog
            v-model="deleteDialog"
            :title="t('case_notebooks.delete_title')"
            :text="t('case_notebooks.delete_message')"
            :confirm-label="t('common.delete')"
            :confirm-color="error"
            :loading="deleting"
            @confirm="deleteNotebook"
        />
    </v-container>
</template>
