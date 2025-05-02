import { LightningElement, api, track } from 'lwc';
import getStudentMaintenanceRequests from '@salesforce/apex/MaintenanceRequestController.getStudentMaintenanceRequests';
import Toast from 'lightning/toast';

const PAGE_SIZE = 5;

const COLUMNS = [
    {
        label: 'Номер заявки',
        fieldName: 'Name',
    },
    {
        label: 'Локация',
        fieldName: 'Location__c'
    },
    {
        label: 'Статус',
        fieldName: 'Status__c',
        sortable: false
    },
    {
        label: 'Дата создания',
        fieldName: 'CreatedDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'long',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        label: 'Тип',
        fieldName: 'Type__c',
        type: 'text',
        wrapText: true,
        sortable: false
    },
    {
        label: 'Описание',
        fieldName: 'Description__c',
        type: 'text',
        wrapText: true,
        sortable: false
    }
];

export default class PortalStudentMaintenanceRequestsList extends LightningElement {
    columns = COLUMNS;

    @track requests = [];
    @track error;
    @track currentPage = 1;
    @track totalPages = 1;
    totalRecords = 0;

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    connectedCallback() {
        this.fetchRequests();
    }

    @api
    async fetchRequests() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));

        try {
            const result = await getStudentMaintenanceRequests({ pageSize: PAGE_SIZE, pageNumber: this.currentPage });
            this.requests = result.requests;
            this.totalRecords = result.total;
            this.totalPages = Math.ceil(this.totalRecords / PAGE_SIZE);
            this.error = null;
        } catch (err) {
            this.requests = [];
            this.totalPages = 1;
            this.totalRecords = 0;
            this.error = err.body?.message || 'Не удалось загрузить заявки.';
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }

    handleNext() {
        if (!this.isLastPage) {
            this.currentPage++;
            this.fetchRequests();
        }
    }

    handlePrevious() {
        if (!this.isFirstPage) {
            this.currentPage--;
            this.fetchRequests();
        }
    }
}