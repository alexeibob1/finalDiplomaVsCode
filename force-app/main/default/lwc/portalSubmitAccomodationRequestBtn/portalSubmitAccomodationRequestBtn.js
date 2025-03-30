import { api, LightningElement } from 'lwc';
import isRequestSubmissionAvailable from '@salesforce/apex/AccomodationRequestController.isRequestSubmissionAvailable';
import isRegistrationAvailable from '@salesforce/apex/AccomodationRequestController.isRegistrationAvailable';
import createAccommodationRequest from '@salesforce/apex/AccomodationRequestController.createAccommodationRequest';
import Toast from 'lightning/toast';

export default class PortalSubmitAccomodationRequestBtn extends LightningElement {
    error = undefined;

    isRegistrationAvailable = false;
    isRequestSubmissionAvailable = false;

    connectedCallback() {
        this.checkButtonAvailability();
    }

    async handleRequest() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
        try {
            await createAccommodationRequest();
            this.showToast('Успешно', 'Заявка успешно подана', 'success');
            this.checkButtonAvailability();
            this.dispatchEvent(new CustomEvent('requestcreated'));

            this.error = undefined;
        } catch (error) {
            this.error = error.body.message;
            this.showToast('Ошибка', 'Произошла ошибка', 'error');
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant, mode: 'dismissible' });
    }

    async checkButtonAvailability() {
        this.isRegistrationAvailable = await isRegistrationAvailable();
        this.isRequestSubmissionAvailable = await isRequestSubmissionAvailable();
    }

    @api
    get isButtonDisabled() {
        return !this.isRegistrationAvailable || !this.isRequestSubmissionAvailable;
    }
}