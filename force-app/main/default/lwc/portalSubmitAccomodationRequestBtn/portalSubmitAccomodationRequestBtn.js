import { api, LightningElement } from 'lwc';
import isRequestSubmissionAvailable from '@salesforce/apex/AccomodationRequestController.isRequestSubmissionAvailable';
import isRegistrationAvailable from '@salesforce/apex/AccomodationRequestController.isRegistrationAvailable';
import createAccommodationRequest from '@salesforce/apex/AccomodationRequestController.createAccommodationRequest';
import Toast from 'lightning/toast';
import ConfirmationModal from 'c/confirmationModal';

export default class PortalSubmitAccomodationRequestBtn extends LightningElement {
    error = undefined;

    isRegistrationAvailable = false;
    isRequestSubmissionAvailable = false;

    showModal = false;

    connectedCallback() {
        this.checkButtonAvailability();
    }

    async handleClick() {
        const result = await ConfirmationModal.open({
            size: 'medium',
            title: 'Подтверждение заявки',
            message: 'Вы уверены, что хотите подать заявку на проживание?',
            confirmLabel: 'Подтвердить',
            cancelLabel: 'Отмена'
        });

        if (result) {
            this.processRequest();
        }
    }

    async processRequest() {
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
            this.closeModal();
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

    openModal() {
        this.showModal = true;
    }

    closeModal() {
        this.showModal = false;
    }
}