import { LightningElement, track } from 'lwc';
import getAttendedEvents from '@salesforce/apex/EventController.getAttendedEvents';

const PAGE_SIZE = 10;

export default class AttendedEventList extends LightningElement {
    @track requests = [];
    @track error;
    @track currentPage = 1;
    total = 0;

    connectedCallback() {
        this.loadData();
    }

    get disablePrev() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage * PAGE_SIZE >= this.total;
    }

    async loadData() {
        try {
            const result = await getAttendedEvents({ pageSize: PAGE_SIZE, pageNumber: this.currentPage });
            this.total = result.total;
            this.requests = result.events.map(req => ({
                ...req,
                formattedDate: this.formatDateTime(req.Event__r.Event_DateTime__c)
            }));
            this.error = null;
        } catch (e) {
            console.error(e);
            this.error = 'Ошибка при загрузке данных';
            this.requests = [];
        }
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.loadData();
        }
    }

    handleNext() {
        if (this.currentPage * PAGE_SIZE < this.total) {
            this.currentPage++;
            this.loadData();
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
