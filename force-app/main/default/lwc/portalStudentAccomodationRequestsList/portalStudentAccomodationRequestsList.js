import { LightningElement, api } from 'lwc';
import getRequestsPaginated from '@salesforce/apex/AccomodationRequestController.getStudentRequestsPaginated';
import cancelRequest from '@salesforce/apex/AccomodationRequestController.cancelRequest';
import Toast from 'lightning/toast';

const actions = [
    { label: 'Отменить заявку', name: 'cancel_request' }
];

const COLUMNS = [
    { label: 'Номер заявки', fieldName: 'Name', sortable: false },
    { label: 'Дата создания', fieldName: 'CreatedDate', type: 'date', sortable: false,
        typeAttributes: { 
            year: "numeric", month: "long", day: "2-digit",
            hour: "2-digit", minute: "2-digit"
        }
    },
    { label: 'Статус', fieldName: 'Status__c', sortable: false },
    { label: 'Место заселения', fieldName: 'Place_Of_Settlement__c', sortable: false },
    {
        label: 'Примечание',
        fieldName: 'Note__c',
        type: 'text',
        wrapText: true,
        sortable: false
    },
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];

export default class PortalStudentAccomodationRequestsList extends LightningElement {
    requests = [];
    columns = COLUMNS;
    error;
    
    pageSize = 5;
    currentPage = 1;
    totalRecords = 0;

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    connectedCallback() {
        this.fetchRequests();
    }

    @api
    async fetchRequests() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));

        const offset = (this.currentPage - 1) * this.pageSize;

        try {
            const result = await getRequestsPaginated({ offset, pageSize: this.pageSize });
            this.requests = result.records;
            this.totalRecords = result.total;
            this.error = undefined;
        } catch (e) {
            this.requests = [];
            this.error = e.body?.message || e.message;
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'cancel_request') {
            try {
                await cancelRequest({ requestId: row.Id });
                this.fetchRequests();
                this.showToast('Успешно', 'Заявка отменена', 'success');
                this.dispatchEvent(new CustomEvent('requestcancelled'));
            } catch (e) {
                this.showToast('Ошибка', e.body?.message || e.message, 'error');
            }
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.fetchRequests();
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.fetchRequests();
        }
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }
    
    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant, mode: 'dismissible' });
    }
}