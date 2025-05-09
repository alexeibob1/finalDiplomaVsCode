import { LightningElement, track, api } from 'lwc';
import getAvailableEventsForStudent from '@salesforce/apex/EventController.getAvailableEventsForStudent';
import createEventRequest from '@salesforce/apex/EventController.createEventRequest';
import Toast from 'lightning/toast';

const PAGE_SIZE = 10;

export default class EventRequestForm extends LightningElement {
    @track events = [];
    @track error;

    connectedCallback() {
        this.loadEvents();
    }

    @api
    async loadEvents() {
        try {
            const result = await getAvailableEventsForStudent({ pageSize: PAGE_SIZE, pageNumber: 1 });

            this.events = result.events.map(event => {
                const alreadyRequested = result.existingEventIds.includes(event.Id);
                const isFull = event.Remaining_Spaces__c === 0;

                return {
                    ...event,
                    formattedDate: this.formatDateTime(event.Event_DateTime__c),
                    buttonDisabled: alreadyRequested || isFull
                };
            });
            this.error = null;
        } catch (e) {
            console.error(e);
            this.error = 'Ошибка при загрузке мероприятий';
        }
    }

    async handleSubmit(event) {
        const eventId = event.currentTarget.dataset.id;

        try {
            await createEventRequest({ eventId });
            Toast.show({ label: 'Успешно', message: 'Заявка отправлена', variant: 'success' });
            // this.loadEvents(); // Refetch to disable button
            this.dispatchEvent(new CustomEvent('refreshrequests'));
        } catch (e) {
            console.error(e);
            Toast.show({ label: 'Ошибка', message: e.body?.message || 'Не удалось отправить заявку', variant: 'error' });
        }
    }

    formatDateTime(dateStr) {
        const date = new Date(dateStr);
        return new Intl.DateTimeFormat('ru-RU', {
            day: 'numeric',
            month: 'long',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(date);
    }
}
