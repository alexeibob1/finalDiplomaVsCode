import { LightningElement } from 'lwc';

export default class PortalEventsPage extends LightningElement {
    isLoading = false;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }

    handleRequestRefresh() {
        const list = this.template.querySelector('c-student-event-requests-list');
        const form = this.template.querySelector('c-event-request-form');

        if (list?.loadRequests) {
            list.loadRequests();
        }
        if (form?.loadEvents) {
            form.loadEvents();
        }
    }
}
