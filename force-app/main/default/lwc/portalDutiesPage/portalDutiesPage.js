import { LightningElement } from 'lwc';

export default class PortalDutiesPage extends LightningElement {
    isLoading = false;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestSubmit(event) {
        const requestList = this.template.querySelector('c-student-duty-month-requests');
        if (requestList) {
            requestList.loadRequests();
        }
    }
}
