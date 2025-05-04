import { LightningElement, track, api } from 'lwc';
import getAvailableEventsForStudent from '@salesforce/apex/EventController.getAvailableEventsForStudent';
import createEventRequest from '@salesforce/apex/EventController.createEventRequest';
import ConfirmationModal from 'c/confirmationModal';
import Toast from 'lightning/toast';

export default class EventRequestForm extends LightningElement {
    @track events = [];
    @track error;

    connectedCallback() {
        this.fetchEvents();
    }

    async fetchEvents() {
        this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
        try {
            const result = await getAvailableEventsForStudent();

            this.events = result.map(event => ({
                ...event,
                isActive: this.isDeletable(event.Remaining_Spaces__c > 0)
            }));
            this.error = null;
        } catch (e) {
            this.error = e.body?.message || 'Ошибка загрузки мероприятий';
        } finally {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
        }
    }

    async handleSubmit(event) {
        const eventId = event.currentTarget.dataset.id;
        const selected = this.events.find(e => e.Id === eventId);

        const result = await ConfirmationModal.open({
            size: 'medium',
            title: 'Подтверждение заявки',
            message: `Вы уверены, что хотите записаться на мероприятие "${selected.Name}"?`,
            confirmLabel: 'Подтвердить',
            cancelLabel: 'Отмена'
        });

        if (result) {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
            try {
                await createEventRequest({ eventId });
                Toast.show({ label: 'Успешно', message: 'Заявка отправлена', variant: 'success' });
                this.fetchEvents();
                this.dispatchEvent(new CustomEvent('requestcreated'));
            } catch (e) {
                Toast.show({ label: 'Ошибка', message: 'Не удалось отправить заявку', variant: 'error' });
            } finally {
                this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
            }
        }
    }
}
