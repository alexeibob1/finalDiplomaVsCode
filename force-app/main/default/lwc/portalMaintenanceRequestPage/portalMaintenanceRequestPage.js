import { LightningElement } from 'lwc';

export default class PortalMaintenanceRequestsPage extends LightningElement {
    isLoading = false;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestCreated() {
        const list = this.template.querySelector('c-portal-student-maintenance-requests-list');
        if (list) {
            list.fetchRequests();
        }
    }
}
