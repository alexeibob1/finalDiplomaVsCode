import { LightningElement } from 'lwc';
import createAccommodationRequest from '@salesforce/apex/AccomodationRequestController.createAccommodationRequest';
import Toast from 'lightning/toast';

export default class PortalSubmitAccomodationRequestBtn extends LightningElement {
    error = undefined;

    async handleRequest() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
        try {
            await createAccommodationRequest();
            this.showToast('Успешно', 'Заявка успешно подана', 'success');
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
        Toast.show({
            label, 
            message, 
            variant,
            mode: 'dismissible'
        });
    }
}