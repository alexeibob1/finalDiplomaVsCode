import { LightningElement, track, api } from 'lwc';
import getStudentEventRequests from '@salesforce/apex/EventController.getStudentEventRequests';
import deleteEventRequest from '@salesforce/apex/EventController.deleteEventRequest';
import ConfirmationModal from 'c/confirmationModal';
import Toast from 'lightning/toast';

export default class StudentEventRequestsList extends LightningElement {
    @track requests = [];
    @track error;

    connectedCallback() {
        this.loadRequests();
    }

    @api
    async loadRequests() {
        try {
            const result = await getStudentEventRequests();
            this.requests = result.map(item => ({
                ...item,
                formattedDate: this.formatDateTime(item.Event__r.Event_DateTime__c),
                isDisabled: !this.isDeletable(item.Event__r?.Event_DateTime__c)
            }));
            this.error = null;
        } catch (e) {
            console.error(e);
            this.error = 'Ошибка при загрузке заявок';
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
        const recordId = event.currentTarget.dataset.id;

        const confirmed = await ConfirmationModal.open({
            title: 'Удалить заявку',
            message: 'Вы уверены, что хотите удалить заявку?',
            confirmLabel: 'Удалить',
            cancelLabel: 'Отмена'
        });

        if (confirmed) {
            try {
                await deleteEventRequest({ requestId: recordId });
                Toast.show({ label: 'Успешно', message: 'Заявка удалена', variant: 'success' });
                this.dispatchEvent(new CustomEvent('refreshrequests'));
            } catch (e) {
                console.error(e);
                Toast.show({ label: 'Ошибка', message: 'Не удалось удалить заявку', variant: 'error' });
                this.dispatchEvent(new CustomEvent('refreshrequests'));
            }
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
