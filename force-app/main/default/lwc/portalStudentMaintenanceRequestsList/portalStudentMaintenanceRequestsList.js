import { LightningElement, api } from 'lwc';
import getStudentMaintenanceRequests from '@salesforce/apex/MaintenanceRequestController.getStudentMaintenanceRequests';
import Toast from 'lightning/toast';

const COLUMNS = [
    {
        label: 'Локация',
        fieldName: 'Location__c'
    },
    {
        label: 'Номер заявки',
        fieldName: 'recordLink',
        type: 'url',
        typeAttributes: {
            label: { fieldName: 'Name' },
            target: '_blank'
        }
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
    }
];

export default class PortalStudentMaintenanceRequestsList extends LightningElement {
    requests = [];
    error;
    columns = COLUMNS;

    connectedCallback() {
        this.fetchRequests();
    }

    @api
    async fetchRequests() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));

        try {
            const result = await getStudentMaintenanceRequests();
            // Build URL links
            this.requests = result.map(req => ({
                ...req,
                recordLink: `/s/detail/${req.Id}` // Adjust `/s/` if your Experience URL structure differs
            }));
            this.error = null;
        } catch (err) {
            this.requests = [];
            this.error = err.body?.message || 'Не удалось загрузить заявки.';
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }
}
