import { LightningElement, api } from 'lwc';
import getStudentRequests from '@salesforce/apex/AccomodationRequestController.getStudentRequests';
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
    {
        type: 'action',
        typeAttributes: { rowActions: actions }
    }
];

export default class PortalStudentAccomodationRequestsList extends LightningElement {
    requests = [];
    error = undefined;

    columns = COLUMNS;

    connectedCallback() {
        this.fetchRequests();
    }

    @api
    async fetchRequests() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } })); 

        try {
            this.requests = await getStudentRequests();
            this.error = undefined;
        } catch (error) {
            this.error = error.body.message;
            this.requests = [];
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
                this.dispatchEvent(new CustomEvent('requestcancelled')); 
                this.showToast('Успешно', 'Заявка успешно отменена', 'success');
            } catch (error) {
                this.showToast('Ошибка', error.body.message, 'error');
            }
        }
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant, mode: 'dismissible' });
    }
}