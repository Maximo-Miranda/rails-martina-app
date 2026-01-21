<script setup lang="ts">
import { ref, computed } from "vue";
import { router } from "@inertiajs/vue3";
import { useTranslations } from "@/composables/useTranslations";
import { useNavigation } from "@/composables/useNavigation";
import PageHeader from "@/components/PageHeader.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import type { CaseNotebook, CaseDocumentItem } from "@/types";

interface LegalCaseRef {
    id: number;
    caseNumber: string;
}

const props = defineProps<{
    legalCase: LegalCaseRef;
    notebook: CaseNotebook;
    documents: CaseDocumentItem[];
}>();

const { t } = useTranslations();
const { navigateTo, isNavigating } = useNavigation();

// Notebook edit state
const showEditDialog = ref(false);
const savingNotebook = ref(false);

// Notebook delete state
const deleteNotebookDialog = ref(false);
const deletingNotebook = ref(false);
const notebookTypes = [
    "principal",
    "medidas_cautelares",
    "ejecucion",
    "incidentes",
    "apelacion",
    "casacion",
    "otro",
];
const notebookForm = ref({
    notebook_type: "",
    code: "",
    description: "",
    volume: 1,
});
const notebookErrors = ref<Record<string, string[]>>({});

// Document state
const showDocumentForm = ref(false);
const editingDocument = ref<CaseDocumentItem | null>(null);
const deleteDialog = ref(false);
const deleteTargetId = ref<number | null>(null);
const deleting = ref(false);
const saving = ref(false);
const fileInput = ref<File | null>(null);

const documentTypes = [
    "demanda",
    "contestacion",
    "auto",
    "sentencia",
    "recurso",
    "memorial",
    "prueba",
    "notificacion",
    "poder",
    "dictamen",
    "acta",
    "otro",
];

const form = ref({
    document_type: "otro",
    name: "",
    description: "",
    folio_start: null as number | null,
    folio_end: null as number | null,
    page_count: null as number | null,
    document_date: null as string | null,
    issuer: "",
});

const errors = ref<Record<string, string[]>>({});

const sortedDocuments = computed(() =>
    [...props.documents].sort(
        (a, b) => (a.itemNumber || 0) - (b.itemNumber || 0),
    ),
);

const openNewDocumentForm = () => {
    editingDocument.value = null;
    fileInput.value = null;
    form.value = {
        document_type: "otro",
        name: "",
        description: "",
        folio_start: null,
        folio_end: null,
        page_count: null,
        document_date: null,
        issuer: "",
    };
    errors.value = {};
    showDocumentForm.value = true;
};

const formatDate = (dateString: string | null) => {
    if (!dateString) return "-";
    return new Date(dateString).toLocaleDateString();
};

const submitDocumentForm = () => {
    saving.value = true;

    const formData = new FormData();
    Object.entries(form.value).forEach(([key, value]) => {
        if (value !== null && value !== "") {
            formData.append(`case_document[${key}]`, String(value));
        }
    });

    if (fileInput.value) {
        formData.append("case_document[file]", fileInput.value);
    }

    const url = `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents`;

    router.post(url, formData, {
        forceFormData: true,
        onSuccess: () => {
            showDocumentForm.value = false;
            saving.value = false;
        },
        onError: (e) => {
            errors.value = e as Record<string, string[]>;
            saving.value = false;
        },
    });
};

const confirmDeleteDocument = (id: number) => {
    deleteTargetId.value = id;
    deleteDialog.value = true;
};

const deleteDocument = () => {
    if (!deleteTargetId.value) return;
    deleting.value = true;

    router.delete(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${deleteTargetId.value}`,
        {
            onFinish: () => {
                deleting.value = false;
                deleteDialog.value = false;
                deleteTargetId.value = null;
            },
        },
    );
};

const goToDocument = (doc: CaseDocumentItem) => {
    navigateTo(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${doc.id}`,
    );
};

const goToDocumentEdit = (doc: CaseDocumentItem) => {
    navigateTo(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}/case_documents/${doc.id}?edit=true`,
    );
};

const goBack = () => {
    navigateTo(`/legal_cases/${props.legalCase.id}?tab=notebooks`);
};

// Notebook edit functions
const openEditNotebook = () => {
    notebookForm.value = {
        notebook_type: props.notebook.notebookType,
        code: props.notebook.code,
        description: props.notebook.description || "",
        volume: props.notebook.volume,
    };
    notebookErrors.value = {};
    showEditDialog.value = true;
};

const submitNotebookForm = () => {
    savingNotebook.value = true;
    router.put(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}`,
        { case_notebook: notebookForm.value },
        {
            onSuccess: () => {
                showEditDialog.value = false;
                savingNotebook.value = false;
            },
            onError: (e) => {
                notebookErrors.value = e as Record<string, string[]>;
                savingNotebook.value = false;
            },
        },
    );
};

const confirmDeleteNotebook = () => {
    deleteNotebookDialog.value = true;
};

const deleteNotebook = () => {
    deletingNotebook.value = true;
    router.delete(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${props.notebook.id}`,
        {
            onFinish: () => {
                deletingNotebook.value = false;
                deleteNotebookDialog.value = false;
            },
        },
    );
};

const handleFileChange = (event: Event) => {
    const target = event.target as HTMLInputElement;
    if (target.files && target.files[0]) {
        fileInput.value = target.files[0];
        if (!form.value.name) {
            form.value.name = target.files[0].name.replace(/\.[^/.]+$/, "");
        }
    }
};
</script>

<template>
    <v-container class="py-6">
        <PageHeader
            :title="notebook.code"
            :subtitle="`${t(`legal_cases.notebook_types.${notebook.notebookType}`)} - ${legalCase.caseNumber}`"
        >
            <template #actions>
                <v-btn
                    variant="outlined"
                    size="small"
                    prepend-icon="mdi-arrow-left"
                    data-testid="case-notebook-btn-back"
                    @click="goBack"
                >
                    {{ t("common.back") }}
                </v-btn>
                <v-btn
                    color="primary"
                    size="small"
                    prepend-icon="mdi-pencil"
                    data-testid="case-notebook-btn-edit"
                    :disabled="isNavigating"
                    @click="openEditNotebook"
                >
                    {{ t("common.edit") }}
                </v-btn>
                <v-btn
                    color="error"
                    variant="outlined"
                    size="small"
                    prepend-icon="mdi-delete"
                    data-testid="case-notebook-btn-delete"
                    :disabled="isNavigating"
                    @click="confirmDeleteNotebook"
                >
                    {{ t("common.delete") }}
                </v-btn>
            </template>
        </PageHeader>

        <!-- Notebook Info -->
        <v-card class="rounded-xl mb-4" elevation="0" border>
            <v-card-text>
                <v-row>
                    <v-col cols="12" md="4">
                        <div class="text-caption text-grey">
                            {{ t("legal_cases.volume") }}
                        </div>
                        <div class="text-body-1">{{ notebook.volume }}</div>
                    </v-col>
                    <v-col cols="12" md="4">
                        <div class="text-caption text-grey">
                            {{ t("legal_cases.documents") }}
                        </div>
                        <div class="text-body-1">
                            {{ notebook.documentsCount }}
                        </div>
                    </v-col>
                    <v-col cols="12" md="4">
                        <div class="text-caption text-grey">
                            {{ t("legal_cases.folios") }}
                        </div>
                        <div class="text-body-1">{{ notebook.folioCount }}</div>
                    </v-col>
                </v-row>
                <v-row v-if="notebook.description">
                    <v-col cols="12">
                        <div class="text-caption text-grey">
                            {{ t("common.description") }}
                        </div>
                        <div class="text-body-2">
                            {{ notebook.description }}
                        </div>
                    </v-col>
                </v-row>
            </v-card-text>
        </v-card>

        <!-- Documents Table -->
        <v-card class="rounded-xl" elevation="0" border>
            <v-card-title class="d-flex align-center justify-space-between">
                <div class="d-flex align-center">
                    <v-icon class="mr-2">mdi-file-document-multiple</v-icon>
                    {{ t("case_documents.title") }}
                </div>
                <v-btn
                    color="primary"
                    size="small"
                    prepend-icon="mdi-plus"
                    data-testid="case-notebook-btn-add-document"
                    @click="openNewDocumentForm"
                >
                    {{ t("case_documents.new") }}
                </v-btn>
            </v-card-title>

            <v-divider />

            <v-table v-if="documents.length > 0" hover>
                <thead>
                    <tr>
                        <th class="text-left">#</th>
                        <th class="text-left">
                            {{ t("case_documents.name") }}
                        </th>
                        <th class="text-left">
                            {{ t("case_documents.document_type") }}
                        </th>
                        <th class="text-left">
                            {{ t("case_documents.foliation") }}
                        </th>
                        <th class="text-left">
                            {{ t("case_documents.document_date") }}
                        </th>
                        <th class="text-center">
                            {{ t("case_documents.ai") }}
                        </th>
                        <th class="text-right">{{ t("common.actions") }}</th>
                    </tr>
                </thead>
                <tbody>
                    <tr
                        v-for="doc in sortedDocuments"
                        :key="doc.id"
                        :data-testid="`case-document-row-${doc.id}`"
                        class="cursor-pointer"
                        @click="goToDocument(doc)"
                    >
                        <td>{{ doc.itemNumber }}</td>
                        <td>{{ doc.name }}</td>
                        <td>
                            <v-chip size="small" variant="tonal">
                                {{
                                    doc.documentType
                                        ? t(
                                              `case_documents.document_types.${doc.documentType}`,
                                          )
                                        : t(
                                              "case_documents.document_types.sin_tipo",
                                          )
                                }}
                            </v-chip>
                        </td>
                        <td>{{ doc.foliation || "-" }}</td>
                        <td>{{ formatDate(doc.documentDate) }}</td>
                        <td class="text-center">
                            <v-icon
                                v-if="doc.aiEnabled"
                                color="success"
                                size="small"
                                >mdi-brain</v-icon
                            >
                            <v-icon v-else color="grey" size="small"
                                >mdi-brain</v-icon
                            >
                        </td>
                        <td class="text-right">
                            <v-tooltip
                                location="top"
                                :text="t('tooltips.view')"
                            >
                                <template #activator="{ props: tooltipProps }">
                                    <v-btn
                                        v-bind="tooltipProps"
                                        icon
                                        variant="text"
                                        size="small"
                                        :data-testid="`case-document-btn-view-${doc.id}`"
                                        @click.stop="goToDocument(doc)"
                                    >
                                        <v-icon>mdi-eye</v-icon>
                                    </v-btn>
                                </template>
                            </v-tooltip>
                            <v-tooltip
                                location="top"
                                :text="t('tooltips.edit')"
                            >
                                <template #activator="{ props: tooltipProps }">
                                    <v-btn
                                        v-bind="tooltipProps"
                                        icon
                                        variant="text"
                                        size="small"
                                        :disabled="isNavigating"
                                        :data-testid="`case-document-btn-edit-${doc.id}`"
                                        @click.stop="goToDocumentEdit(doc)"
                                    >
                                        <v-icon>mdi-pencil</v-icon>
                                    </v-btn>
                                </template>
                            </v-tooltip>
                            <v-tooltip
                                location="top"
                                :text="t('tooltips.delete')"
                            >
                                <template #activator="{ props: tooltipProps }">
                                    <v-btn
                                        v-bind="tooltipProps"
                                        icon
                                        variant="text"
                                        size="small"
                                        color="error"
                                        :data-testid="`case-document-btn-delete-${doc.id}`"
                                        @click.stop="
                                            confirmDeleteDocument(doc.id)
                                        "
                                    >
                                        <v-icon>mdi-delete</v-icon>
                                    </v-btn>
                                </template>
                            </v-tooltip>
                        </td>
                    </tr>
                </tbody>
            </v-table>

            <v-card-text v-else class="text-center py-8">
                <v-icon size="64" color="grey-lighten-1" class="mb-4"
                    >mdi-file-document-outline</v-icon
                >
                <p class="text-grey">{{ t("case_documents.no_documents") }}</p>
                <v-btn
                    color="primary"
                    variant="tonal"
                    class="mt-4"
                    prepend-icon="mdi-plus"
                    data-testid="case-notebook-btn-add-document-empty"
                    @click="openNewDocumentForm"
                >
                    {{ t("case_documents.new") }}
                </v-btn>
            </v-card-text>
        </v-card>

        <!-- Document Form Dialog -->
        <v-dialog v-model="showDocumentForm" max-width="700" persistent>
            <v-card>
                <v-card-title class="d-flex align-center">
                    <v-icon class="mr-2">mdi-file-document</v-icon>
                    {{ t("case_documents.new") }}
                </v-card-title>

                <v-card-text>
                    <v-form @submit.prevent="submitDocumentForm">
                        <v-file-input
                            :label="t('case_documents.file') + ' *'"
                            :error-messages="errors.file"
                            data-testid="case-document-input-file"
                            prepend-icon="mdi-paperclip"
                            accept=".pdf,.doc,.docx,.xls,.xlsx,.pptx,.odt,.txt,.md,.csv"
                            required
                            @change="handleFileChange"
                        />

                        <v-row class="mt-2">
                            <v-col cols="12" md="6">
                                <v-select
                                    v-model="form.document_type"
                                    :items="documentTypes"
                                    :label="
                                        t('case_documents.document_type') + ' *'
                                    "
                                    :error-messages="errors.document_type"
                                    data-testid="case-document-input-type"
                                    required
                                >
                                    <template
                                        #item="{ props: itemProps, item }"
                                    >
                                        <v-list-item
                                            v-bind="itemProps"
                                            :title="
                                                t(
                                                    `case_documents.document_types.${item.raw}`,
                                                )
                                            "
                                        >
                                        </v-list-item>
                                    </template>
                                    <template #selection="{ item }">
                                        {{
                                            t(
                                                `case_documents.document_types.${item.raw}`,
                                            )
                                        }}
                                    </template>
                                </v-select>
                            </v-col>
                            <v-col cols="12" md="6">
                                <v-text-field
                                    v-model="form.name"
                                    :label="t('case_documents.name') + ' *'"
                                    :error-messages="errors.name"
                                    data-testid="case-document-input-name"
                                    required
                                />
                            </v-col>
                        </v-row>

                        <v-textarea
                            v-model="form.description"
                            :label="t('case_documents.description') + ' *'"
                            :error-messages="errors.description"
                            data-testid="case-document-input-description"
                            rows="2"
                            class="mt-2"
                            required
                        />

                        <v-row class="mt-2">
                            <v-col cols="4">
                                <v-text-field
                                    v-model.number="form.folio_start"
                                    :label="
                                        t('case_documents.folio_start') + ' *'
                                    "
                                    :error-messages="errors.folio_start"
                                    data-testid="case-document-input-folio-start"
                                    type="number"
                                    min="1"
                                    required
                                />
                            </v-col>
                            <v-col cols="4">
                                <v-text-field
                                    v-model.number="form.folio_end"
                                    :label="
                                        t('case_documents.folio_end') + ' *'
                                    "
                                    :error-messages="errors.folio_end"
                                    data-testid="case-document-input-folio-end"
                                    type="number"
                                    min="1"
                                    required
                                />
                            </v-col>
                            <v-col cols="4">
                                <v-text-field
                                    v-model.number="form.page_count"
                                    :label="
                                        t('case_documents.page_count') + ' *'
                                    "
                                    :error-messages="errors.page_count"
                                    data-testid="case-document-input-page-count"
                                    type="number"
                                    min="1"
                                    required
                                />
                            </v-col>
                        </v-row>

                        <v-row class="mt-2">
                            <v-col cols="12" md="6">
                                <v-text-field
                                    v-model="form.document_date"
                                    :label="
                                        t('case_documents.document_date') + ' *'
                                    "
                                    :error-messages="errors.document_date"
                                    data-testid="case-document-input-date"
                                    type="date"
                                    required
                                />
                            </v-col>
                            <v-col cols="12" md="6">
                                <v-text-field
                                    v-model="form.issuer"
                                    :label="t('case_documents.issuer') + ' *'"
                                    :error-messages="errors.issuer"
                                    data-testid="case-document-input-issuer"
                                    :hint="t('case_documents.issuer_hint')"
                                    required
                                />
                            </v-col>
                        </v-row>
                    </v-form>
                </v-card-text>

                <v-card-actions>
                    <v-spacer />
                    <v-btn
                        variant="text"
                        :disabled="saving"
                        data-testid="case-document-btn-cancel"
                        @click="showDocumentForm = false"
                    >
                        {{ t("common.cancel") }}
                    </v-btn>
                    <v-btn
                        color="primary"
                        :loading="saving"
                        data-testid="case-document-btn-submit"
                        @click="submitDocumentForm"
                    >
                        {{ t("common.create") }}
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Notebook Edit Dialog -->
        <v-dialog v-model="showEditDialog" max-width="600" persistent>
            <v-card>
                <v-card-title class="d-flex align-center">
                    <v-icon class="mr-2">mdi-folder</v-icon>
                    {{ t("case_notebooks.edit") }}
                </v-card-title>

                <v-card-text>
                    <v-form @submit.prevent="submitNotebookForm">
                        <v-select
                            v-model="notebookForm.notebook_type"
                            :items="notebookTypes"
                            :label="t('case_notebooks.notebook_type')"
                            :error-messages="notebookErrors.notebook_type"
                            data-testid="case-notebook-edit-input-type"
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
                            v-model="notebookForm.code"
                            :label="t('case_notebooks.code')"
                            :error-messages="notebookErrors.code"
                            data-testid="case-notebook-edit-input-code"
                            required
                            class="mt-4"
                        />

                        <v-textarea
                            v-model="notebookForm.description"
                            :label="t('case_notebooks.description')"
                            :error-messages="notebookErrors.description"
                            data-testid="case-notebook-edit-input-description"
                            rows="3"
                            class="mt-4"
                        />

                        <v-text-field
                            v-model.number="notebookForm.volume"
                            :label="t('case_notebooks.volume')"
                            :error-messages="notebookErrors.volume"
                            data-testid="case-notebook-edit-input-volume"
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
                        :disabled="savingNotebook"
                        data-testid="case-notebook-edit-btn-cancel"
                        @click="showEditDialog = false"
                    >
                        {{ t("common.cancel") }}
                    </v-btn>
                    <v-btn
                        color="primary"
                        :loading="savingNotebook"
                        data-testid="case-notebook-edit-btn-submit"
                        @click="submitNotebookForm"
                    >
                        {{ t("common.save") }}
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Delete Document Confirmation -->
        <ConfirmDialog
            v-model="deleteDialog"
            :title="t('case_documents.delete_title')"
            :text="t('case_documents.delete_message')"
            :confirm-label="t('common.delete')"
            confirm-color="error"
            :loading="deleting"
            @confirm="deleteDocument"
        />

        <!-- Delete Notebook Confirmation -->
        <ConfirmDialog
            v-model="deleteNotebookDialog"
            :title="t('case_notebooks.delete_title')"
            :text="t('case_notebooks.delete_message')"
            :confirm-label="t('common.delete')"
            confirm-color="error"
            :loading="deletingNotebook"
            @confirm="deleteNotebook"
        />
    </v-container>
</template>

<style scoped>
.cursor-pointer {
    cursor: pointer;
}
</style>
