import { LightningElement, track, api } from 'lwc';
import getAvailableEventsForStudent from '@salesforce/apex/EventController.getAvailableEventsForStudent';
import createEventRequest from '@salesforce/apex/EventController.createEventRequest';
import Toast from 'lightning/toast';
import ConfirmationModal from 'c/confirmationModal';

const PAGE_SIZE = 10;

export default class EventRequestForm extends LightningElement {
    @track events = [];
    @track error;
    @track currentPage = 1;
    @track total = 0;

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage * PAGE_SIZE >= this.total;
    }

    nextPage() {
        if (!this.isLastPage) {
            this.currentPage++;
            this.fetchEvents();
        }
    }

    prevPage() {
        if (!this.isFirstPage) {
            this.currentPage--;
            this.fetchEvents();
        }
    }

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
        const selected = this.events.find(e => e.Id === eventId);

        const result = await ConfirmationModal.open({
            size: 'medium',
            title: 'Подтверждение заявки',
            message: `Вы уверены, что хотите записаться на мероприятие "${selected.Name}"? ` + 
                (!this.isDeletable(selected.Event_DateTime__c) ? 'До мероприятия осталось меньше суток, поэтому подаваемая заявка не сможет быть отменена.' : ''),
            confirmLabel: 'Подтвердить',
            cancelLabel: 'Отмена'
        });

        if (result) {
            this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: true } }));
            try {
                await createEventRequest({ eventId });
                Toast.show({ label: 'Успешно', message: 'Заявка отправлена', variant: 'success' });
                this.dispatchEvent(new CustomEvent('refreshrequests'));
            } catch (e) {
                Toast.show({ label: 'Ошибка', message: 'Не удалось отправить заявку', variant: 'error' });
            } finally {
                this.dispatchEvent(new CustomEvent('loading', { detail: { isLoading: false } }));
            }
        }
    }

    isDeletable(eventDate) {
        const now = new Date();
        const eventTime = new Date(eventDate);
        const oneDayBefore = new Date(eventTime);
        oneDayBefore.setDate(eventTime.getDate() - 1);
        return now < oneDayBefore;
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
