import { LightningElement } from 'lwc';

export default class PortalEventsPage extends LightningElement {
    isLoading = false;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestCreated() {
        const list = this.template.querySelector('c-student-event-requests-list');
        if (list) {
            list.fetchRequests();
        }
    }
}
