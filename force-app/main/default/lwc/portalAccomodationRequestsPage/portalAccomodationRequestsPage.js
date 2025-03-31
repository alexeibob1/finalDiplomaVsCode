import { LightningElement } from 'lwc';

export default class PortalAccomodationRequestsPage extends LightningElement {
    isLoading = false;
    error = undefined;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestCreated() {
        const requestList = this.template.querySelector('c-portal-student-accomodation-requests-list');
        if (requestList) {
            requestList.fetchRequests();
        }
    }

    handleRequestCancelled() {
        const requestBtn = this.template.querySelector('c-portal-submit-accomodation-request-btn');
        if (requestBtn) {
            requestBtn.checkButtonAvailability();
        }
    }
}