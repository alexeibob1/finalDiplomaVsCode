import { LightningElement, track } from 'lwc';
import getApprovedUpcomingDuties from '@salesforce/apex/DutyController.getApprovedUpcomingDuties';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';

export default class NearestDuties extends LightningElement {
    @track requests = [];
    @track total = 0;
    @track dutiesCount = 0;
    @track error;
    @track pageSize = 5;
    @track pageNumber = 0;

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        try {
            const contact = await getCurrentUserContact();
            this.dutiesCount = contact.Current_Study_Year_Duties__c || 0;

            const result = await getApprovedUpcomingDuties({
                pageSize: this.pageSize,
                pageNumber: this.pageNumber
            });

            this.requests = result.requests.map(req => ({
                ...req,
                formattedDate: this.formatDate(req.Duty_Date__c)
            }));
            this.total = result.total;
            this.error = null;
        } catch (e) {
            console.error(e);
            this.error = 'Ошибка загрузки данных.';
        }
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return new Intl.DateTimeFormat('ru-RU', {
            day: 'numeric',
            month: 'long',
            year: 'numeric'
        }).format(date);
    }    

    handleNext() {
        this.pageNumber++;
        this.loadData();
    }

    handlePrev() {
        if (this.pageNumber > 0) {
            this.pageNumber--;
            this.loadData();
        }
    }

    get isFirstPage() {
        return this.pageNumber === 0;
    }

    get isLastPage() {
        return this.pageNumber + 1 >= this.totalPages;
    }

    get totalPages() {
        return this.total > 0 ? Math.ceil(this.total / this.pageSize) : 0;
    }

    get currentPage() {
        return this.total > 0 ? this.pageNumber + 1 : 0;
    }

    get hasRequests() {
        return this.requests.length > 0;
    }
}
