import { LightningElement, track, api } from 'lwc';
import getStudentEventRequests from '@salesforce/apex/EventController.getStudentEventRequests';
import deleteEventRequest from '@salesforce/apex/EventController.deleteEventRequest';
import ConfirmationModal from 'c/confirmationModal';
import Toast from 'lightning/toast';

export default class StudentEventRequestsList extends LightningElement {
    @track requests = [];
    @track error;

    connectedCallback() {
        this.fetchRequests();
    }

    @api
    async fetchRequests() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
        try {
            const result = await getStudentEventRequests();
            this.requests = result.map(req => ({
                ...req,
                isDeletable: this.isDeletable(req.Event__r?.Event_DateTime__c)
            }));
            this.error = null;
        } catch (err) {
            this.requests = [];
            this.error = err.body?.message || 'Ошибка загрузки заявок';
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }

    isDeletable(eventDate) {
        const now = new Date();
        const eventTime = new Date(eventDate);
        const oneDayBefore = new Date(eventTime);
        oneDayBefore.setDate(eventTime.getDate() - 1);
        return now < oneDayBefore;
    }

    async handleDelete(event) {
        const requestId = event.currentTarget.dataset.id;

        const result = await ConfirmationModal.open({
            title: 'Удалить заявку?',
            message: 'Вы уверены, что хотите удалить эту заявку?',
            confirmLabel: 'Удалить',
            cancelLabel: 'Отмена'
        });

        if (result) {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
            try {
                await deleteEventRequest({ requestId });
                Toast.show({ label: 'Удалено', message: 'Заявка удалена', variant: 'success' });
                this.fetchRequests();
            } catch (err) {
                Toast.show({ label: 'Ошибка', message: 'Не удалось удалить заявку', variant: 'error' });
            } finally {
                this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
            }
        }
    }
}
