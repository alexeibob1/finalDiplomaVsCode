import { LightningElement, track } from 'lwc';
import createAccommodationRequest from '@salesforce/apex/AccomodationRequestController.createAccommodationRequest';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccommodationRequestBtn extends LightningElement {
    @track isLoading = false;

    async handleRequest() {
        this.isLoading = true;

        try {
            const requestId = await createAccommodationRequest();
            this.showToast('Success', 'Accommodation request submitted!', 'success');
        } catch (error) {
            this.showToast('Error', error.body ? error.body.message : 'An error occurred', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}