import { LightningElement } from 'lwc';

export default class PortalAccomodationRequestsPage extends LightningElement {
    isLoading = false;
    error = undefined;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestCreated() {
        const requestList = this.template.querySelector('c-portal-student-accomodation-requests-list');
        console.log('requestLine elem', requestList);
        if (requestList) {
            requestList.fetchRequests();
        }
    }
}