import { LightningElement, api } from 'lwc';
import getStudentRequests from '@salesforce/apex/AccomodationRequestController.getStudentRequests';

const COLUMNS = [
    { label: 'Номер заявки', fieldName: 'Name', type: 'text' },
    { label: 'Дата создания', fieldName: 'CreatedDate', type: 'date', 
        typeAttributes: { 
            year: "numeric", month: "long", day: "2-digit",
            hour: "2-digit", minute: "2-digit"
        }
    },
    { label: 'Статус', fieldName: 'Status__c', type: 'text' }
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
}