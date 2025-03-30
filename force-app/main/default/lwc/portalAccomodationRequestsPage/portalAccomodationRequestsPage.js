import { LightningElement } from 'lwc';

export default class PortalAccomodationRequestsPage extends LightningElement {
    isLoading = false;
    error = undefined;

    handleLoading(event) {
        this.isLoading = event.detail.isLoading;
    }
}