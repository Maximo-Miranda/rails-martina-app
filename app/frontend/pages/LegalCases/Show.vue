<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { router, usePage } from "@inertiajs/vue3";
import { useTranslations } from "@/composables/useTranslations";
import { useNavigation } from "@/composables/useNavigation";
import PageHeader from "@/components/PageHeader.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import type {
    LegalCaseDetail,
    CaseNotebook,
    CourtOrder,
    CaseReminder,
} from "@/types";

const props = defineProps<{
    legalCase: LegalCaseDetail;
    notebooks: CaseNotebook[];
    courtOrders: CourtOrder[];
    reminders: CaseReminder[];
}>();

const { t } = useTranslations();
const { navigateTo } = useNavigation();

const page = usePage();

// Get initial tab from URL query parameter
const getInitialTab = (): string => {
    const url = new URL(page.url, window.location.origin);
    const tab = url.searchParams.get("tab");
    const validTabs = ["info", "notebooks", "orders", "reminders"];
    return tab && validTabs.includes(tab) ? tab : "info";
};

const activeTab = ref(getInitialTab());

// Sync tab changes with URL (without page reload)
watch(activeTab, (newTab) => {
    const url = new URL(window.location.href);
    if (newTab === "info") {
        url.searchParams.delete("tab");
    } else {
        url.searchParams.set("tab", newTab);
    }
    window.history.replaceState({}, "", url.toString());
});

const deleteDialog = ref(false);
const deleting = ref(false);

// Notebook delete state
const deleteNotebookDialog = ref(false);
const deleteNotebookTargetId = ref<number | null>(null);
const deletingNotebook = ref(false);

const formatDate = (dateString: string | null) => {
    if (!dateString) return "-";
    return new Date(dateString).toLocaleDateString();
};

const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleString();
};

const getStatusColor = (status: string) => {
    switch (status) {
        case "activo":
            return "success";
        case "archivado":
            return "grey";
        case "terminado":
            return "info";
        case "suspendido":
            return "warning";
        case "pendiente":
            return "warning";
        case "cumplido":
            return "success";
        case "vencido":
            return "error";
        default:
            return "grey";
    }
};

const upcomingReminders = computed(() =>
    props.reminders.filter(
        (r) => new Date(r.reminderAt) > new Date() && !r.acknowledged,
    ),
);

const overdueOrders = computed(() =>
    props.courtOrders.filter((o) => o.overdue),
);

const confirmDelete = () => {
    deleting.value = true;
    router.delete(`/legal_cases/${props.legalCase.id}`, {
        onFinish: () => {
            deleting.value = false;
            deleteDialog.value = false;
        },
    });
};

const confirmDeleteNotebook = (id: number) => {
    deleteNotebookTargetId.value = id;
    deleteNotebookDialog.value = true;
};

const deleteNotebook = () => {
    if (!deleteNotebookTargetId.value) return;
    deletingNotebook.value = true;
    router.delete(
        `/legal_cases/${props.legalCase.id}/case_notebooks/${deleteNotebookTargetId.value}`,
        {
            onFinish: () => {
                deletingNotebook.value = false;
                deleteNotebookDialog.value = false;
                deleteNotebookTargetId.value = null;
            },
        },
    );
};
</script>

<template>
    <v-container class="py-6">
        <PageHeader
            :title="legalCase.caseNumber"
            :subtitle="`${legalCase.plaintiff} vs ${legalCase.defendant}`"
        >
            <template #actions>
                <v-btn
                    variant="outlined"
                    size="small"
                    prepend-icon="mdi-arrow-left"
                    data-testid="legal-case-btn-back"
                    @click="navigateTo('/legal_cases')"
                >
                    {{ t("common.back") }}
                </v-btn>
                <v-btn
                    color="primary"
                    size="small"
                    prepend-icon="mdi-pencil"
                    data-testid="legal-case-btn-edit"
                    @click="navigateTo(`/legal_cases/${legalCase.id}/edit`)"
                >
                    {{ t("common.edit") }}
                </v-btn>
                <v-btn
                    color="error"
                    variant="outlined"
                    size="small"
                    prepend-icon="mdi-delete"
                    data-testid="legal-case-btn-delete"
                    @click="deleteDialog = true"
                >
                    {{ t("common.delete") }}
                </v-btn>
            </template>
        </PageHeader>

        <!-- Alerts -->
        <v-alert
            v-if="upcomingReminders.length > 0"
            type="warning"
            variant="tonal"
            class="mb-4"
            closable
        >
            {{
                t("legal_cases.upcoming_reminders", {
                    count: upcomingReminders.length,
                })
            }}
        </v-alert>

        <v-alert
            v-if="overdueOrders.length > 0"
            type="error"
            variant="tonal"
            class="mb-4"
            closable
        >
            {{
                t("legal_cases.overdue_orders", { count: overdueOrders.length })
            }}
        </v-alert>

        <!-- Tabs -->
        <v-card class="rounded-xl" elevation="0" border>
            <v-tabs v-model="activeTab" color="primary">
                <v-tab value="info" data-testid="legal-case-tab-info">
                    <v-icon start>mdi-information</v-icon>
                    {{ t("legal_cases.tabs.info") }}
                </v-tab>
                <v-tab value="notebooks" data-testid="legal-case-tab-notebooks">
                    <v-icon start>mdi-folder-multiple</v-icon>
                    {{ t("legal_cases.tabs.notebooks") }}
                    <v-chip size="x-small" class="ml-2">{{
                        notebooks.length
                    }}</v-chip>
                </v-tab>
                <v-tab value="orders" data-testid="legal-case-tab-orders">
                    <v-icon start>mdi-gavel</v-icon>
                    {{ t("legal_cases.tabs.orders") }}
                    <v-chip size="x-small" class="ml-2">{{
                        courtOrders.length
                    }}</v-chip>
                </v-tab>
                <v-tab value="reminders" data-testid="legal-case-tab-reminders">
                    <v-icon start>mdi-bell</v-icon>
                    {{ t("legal_cases.tabs.reminders") }}
                    <v-chip size="x-small" class="ml-2">{{
                        reminders.length
                    }}</v-chip>
                </v-tab>
            </v-tabs>

            <v-divider />

            <v-tabs-window v-model="activeTab">
                <!-- Info Tab -->
                <v-tabs-window-item value="info">
                    <v-card-text>
                        <v-row>
                            <v-col cols="12" md="6">
                                <h3 class="text-h6 mb-3">
                                    {{ t("legal_cases.case_info") }}
                                </h3>
                                <v-list density="compact">
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-briefcase</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.case_number")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.caseNumber
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-bank</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.court")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.court
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-scale-balance</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.specialty")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>
                                            <v-chip
                                                size="small"
                                                variant="tonal"
                                            >
                                                {{
                                                    t(
                                                        `legal_cases.specialties.${legalCase.specialty}`,
                                                    )
                                                }}
                                            </v-chip>
                                        </v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-tag</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.status")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>
                                            <v-chip
                                                size="small"
                                                :color="
                                                    getStatusColor(
                                                        legalCase.status,
                                                    )
                                                "
                                                variant="tonal"
                                            >
                                                {{
                                                    t(
                                                        `legal_cases.statuses.${legalCase.status}`,
                                                    )
                                                }}
                                            </v-chip>
                                        </v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-file-document</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.action_type")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.actionType
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-calendar</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.filing_date")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            formatDate(legalCase.filingDate)
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                </v-list>
                            </v-col>

                            <v-col cols="12" md="6">
                                <h3 class="text-h6 mb-3">
                                    {{ t("legal_cases.parties") }}
                                </h3>
                                <v-list density="compact">
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon color="primary"
                                                >mdi-account</v-icon
                                            >
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.plaintiff")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.plaintiff
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item
                                        v-if="legalCase.plaintiffLawyer"
                                    >
                                        <template #prepend>
                                            <v-icon color="primary"
                                                >mdi-account-tie</v-icon
                                            >
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.plaintiff_lawyer")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.plaintiffLawyer
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon color="error"
                                                >mdi-account</v-icon
                                            >
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.defendant")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.defendant
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item
                                        v-if="legalCase.defendantLawyer"
                                    >
                                        <template #prepend>
                                            <v-icon color="error"
                                                >mdi-account-tie</v-icon
                                            >
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.defendant_lawyer")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.defendantLawyer
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                </v-list>

                                <h3 class="text-h6 mb-3 mt-4">
                                    {{ t("legal_cases.lawyer_info") }}
                                </h3>
                                <v-list density="compact">
                                    <v-list-item>
                                        <template #prepend>
                                            <v-icon>mdi-account-tie</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.lawyer_in_charge")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.lawyerInCharge
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item
                                        v-if="legalCase.lawyerProfessionalCard"
                                    >
                                        <template #prepend>
                                            <v-icon
                                                >mdi-card-account-details</v-icon
                                            >
                                        </template>
                                        <v-list-item-title>{{
                                            t(
                                                "legal_cases.lawyer_professional_card",
                                            )
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.lawyerProfessionalCard
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item v-if="legalCase.lawyerPhone">
                                        <template #prepend>
                                            <v-icon>mdi-phone</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.lawyer_phone")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.lawyerPhone
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                    <v-list-item v-if="legalCase.lawyerEmail">
                                        <template #prepend>
                                            <v-icon>mdi-email</v-icon>
                                        </template>
                                        <v-list-item-title>{{
                                            t("legal_cases.lawyer_email")
                                        }}</v-list-item-title>
                                        <v-list-item-subtitle>{{
                                            legalCase.lawyerEmail
                                        }}</v-list-item-subtitle>
                                    </v-list-item>
                                </v-list>
                            </v-col>
                        </v-row>

                        <v-row v-if="legalCase.notes" class="mt-4">
                            <v-col cols="12">
                                <h3 class="text-h6 mb-3">
                                    {{ t("legal_cases.notes") }}
                                </h3>
                                <v-card variant="outlined" class="pa-4">
                                    <p
                                        class="text-body-2"
                                        style="white-space: pre-wrap"
                                    >
                                        {{ legalCase.notes }}
                                    </p>
                                </v-card>
                            </v-col>
                        </v-row>
                    </v-card-text>
                </v-tabs-window-item>

                <!-- Notebooks Tab -->
                <v-tabs-window-item value="notebooks">
                    <v-card-text>
                        <div class="d-flex justify-end mb-4">
                            <v-btn
                                color="primary"
                                size="small"
                                prepend-icon="mdi-plus"
                                data-testid="legal-case-btn-add-notebook"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/case_notebooks/new`,
                                    )
                                "
                            >
                                {{ t("legal_cases.add_notebook") }}
                            </v-btn>
                        </div>

                        <v-list v-if="notebooks.length > 0">
                            <v-list-item
                                v-for="notebook in notebooks"
                                :key="notebook.id"
                                :data-testid="`legal-case-notebook-${notebook.id}`"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/case_notebooks/${notebook.id}`,
                                    )
                                "
                            >
                                <template #prepend>
                                    <v-icon>mdi-folder</v-icon>
                                </template>
                                <v-list-item-title>
                                    {{ notebook.code }} -
                                    {{
                                        t(
                                            `legal_cases.notebook_types.${notebook.notebookType}`,
                                        )
                                    }}
                                </v-list-item-title>
                                <v-list-item-subtitle>
                                    {{ notebook.documentsCount }}
                                    {{ t("legal_cases.documents") }} •
                                    {{ notebook.folioCount }}
                                    {{ t("legal_cases.folios") }}
                                </v-list-item-subtitle>
                                <template #append>
                                    <v-chip
                                        size="small"
                                        variant="tonal"
                                        class="mr-2"
                                    >
                                        {{ t("legal_cases.volume") }}
                                        {{ notebook.volume }}
                                    </v-chip>
                                    <v-tooltip
                                        location="top"
                                        :text="t('tooltips.delete')"
                                    >
                                        <template
                                            #activator="{ props: tooltipProps }"
                                        >
                                            <v-btn
                                                v-bind="tooltipProps"
                                                icon
                                                variant="text"
                                                size="small"
                                                color="error"
                                                :data-testid="`legal-case-notebook-btn-delete-${notebook.id}`"
                                                @click.stop="
                                                    confirmDeleteNotebook(
                                                        notebook.id,
                                                    )
                                                "
                                            >
                                                <v-icon>mdi-delete</v-icon>
                                            </v-btn>
                                        </template>
                                    </v-tooltip>
                                </template>
                            </v-list-item>
                        </v-list>

                        <v-alert v-else type="info" variant="tonal">
                            {{ t("legal_cases.no_notebooks") }}
                        </v-alert>
                    </v-card-text>
                </v-tabs-window-item>

                <!-- Court Orders Tab -->
                <v-tabs-window-item value="orders">
                    <v-card-text>
                        <div class="d-flex justify-end mb-4">
                            <v-btn
                                color="primary"
                                size="small"
                                prepend-icon="mdi-plus"
                                data-testid="legal-case-btn-add-order"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/court_orders/new`,
                                    )
                                "
                            >
                                {{ t("legal_cases.add_order") }}
                            </v-btn>
                        </div>

                        <v-list v-if="courtOrders.length > 0">
                            <v-list-item
                                v-for="order in courtOrders"
                                :key="order.id"
                                :data-testid="`legal-case-order-${order.id}`"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/court_orders/${order.id}`,
                                    )
                                "
                            >
                                <template #prepend>
                                    <v-icon
                                        :color="order.overdue ? 'error' : ''"
                                        >mdi-gavel</v-icon
                                    >
                                </template>
                                <v-list-item-title>
                                    {{
                                        t(
                                            `legal_cases.order_types.${order.orderType}`,
                                        )
                                    }}
                                </v-list-item-title>
                                <v-list-item-subtitle>
                                    {{ formatDate(order.orderDate) }}
                                    <template v-if="order.deadline">
                                        • {{ t("legal_cases.deadline") }}:
                                        {{ formatDate(order.deadline) }}
                                    </template>
                                </v-list-item-subtitle>
                                <template #append>
                                    <v-chip
                                        size="small"
                                        :color="getStatusColor(order.status)"
                                        variant="tonal"
                                    >
                                        {{
                                            t(
                                                `legal_cases.order_statuses.${order.status}`,
                                            )
                                        }}
                                    </v-chip>
                                </template>
                            </v-list-item>
                        </v-list>

                        <v-alert v-else type="info" variant="tonal">
                            {{ t("legal_cases.no_orders") }}
                        </v-alert>
                    </v-card-text>
                </v-tabs-window-item>

                <!-- Reminders Tab -->
                <v-tabs-window-item value="reminders">
                    <v-card-text>
                        <div class="d-flex justify-end mb-4">
                            <v-btn
                                color="primary"
                                size="small"
                                prepend-icon="mdi-plus"
                                data-testid="legal-case-btn-add-reminder"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/case_reminders/new`,
                                    )
                                "
                            >
                                {{ t("legal_cases.add_reminder") }}
                            </v-btn>
                        </div>

                        <v-list v-if="reminders.length > 0">
                            <v-list-item
                                v-for="reminder in reminders"
                                :key="reminder.id"
                                :data-testid="`legal-case-reminder-${reminder.id}`"
                                @click="
                                    navigateTo(
                                        `/legal_cases/${legalCase.id}/case_reminders/${reminder.id}`,
                                    )
                                "
                            >
                                <template #prepend>
                                    <v-icon
                                        :color="
                                            reminder.acknowledged
                                                ? 'success'
                                                : 'warning'
                                        "
                                    >
                                        {{
                                            reminder.acknowledged
                                                ? "mdi-bell-check"
                                                : "mdi-bell"
                                        }}
                                    </v-icon>
                                </template>
                                <v-list-item-title>{{
                                    reminder.title
                                }}</v-list-item-title>
                                <v-list-item-subtitle>
                                    {{ reminder.displayType }} •
                                    {{ formatDateTime(reminder.reminderAt) }}
                                    <template v-if="reminder.location">
                                        • {{ reminder.location }}
                                    </template>
                                </v-list-item-subtitle>
                                <template #append>
                                    <v-chip
                                        v-if="reminder.acknowledged"
                                        size="small"
                                        color="success"
                                        variant="tonal"
                                    >
                                        {{ t("legal_cases.acknowledged") }}
                                    </v-chip>
                                </template>
                            </v-list-item>
                        </v-list>

                        <v-alert v-else type="info" variant="tonal">
                            {{ t("legal_cases.no_reminders") }}
                        </v-alert>
                    </v-card-text>
                </v-tabs-window-item>
            </v-tabs-window>
        </v-card>

        <ConfirmDialog
            v-model="deleteDialog"
            :title="t('legal_cases.delete_title')"
            :text="t('legal_cases.delete_message')"
            :confirm-label="t('common.delete')"
            :cancel-label="t('common.cancel')"
            confirm-color="error"
            :loading="deleting"
            @confirm="confirmDelete"
        />

        <ConfirmDialog
            v-model="deleteNotebookDialog"
            :title="t('case_notebooks.delete_title')"
            :text="t('case_notebooks.delete_message')"
            :confirm-label="t('common.delete')"
            :cancel-label="t('common.cancel')"
            confirm-color="error"
            :loading="deletingNotebook"
            @confirm="deleteNotebook"
        />
    </v-container>
</template>
