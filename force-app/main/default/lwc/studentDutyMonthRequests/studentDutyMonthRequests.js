import { LightningElement, track, api } from 'lwc';
import getStudentDutyRequests from '@salesforce/apex/DutyController.getStudentDutyRequests';
import deleteDutyRequest from '@salesforce/apex/DutyController.deleteDutyRequest';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';
import Toast from 'lightning/toast';

const PAGE_SIZE = 5;

export default class StudentDutyMonthRequests extends LightningElement {
    @track requests = [];
    @track currentPage = 1;
    @track totalPages = 1;
    @track totalCount = 0;
    @track error;

    studentId;

    connectedCallback() {
        this.init();
    }

    async init() {
        this.dispatchLoading(true);
        try {
            const contact = await getCurrentUserContact();
            this.studentId = contact?.Id;
            await this.loadRequests();
        } catch (e) {
            this.error = 'Ошибка при загрузке заявок';
            console.error(e);
        } finally {
            this.dispatchLoading(false);
        }
    }

    @api
    async loadRequests() {
        this.dispatchLoading(true);
        try {
            const result = await getStudentDutyRequests({
                studentId: this.studentId,
                pageSize: PAGE_SIZE,
                pageNumber: this.currentPage
            });
            this.requests = result.requests;
            this.totalCount = result.total;
            this.totalPages = Math.ceil(this.totalCount / PAGE_SIZE);
            this.error = null;
        } catch (e) {
            this.requests = [];
            this.error = 'Не удалось загрузить заявки';
            console.error(e);
        } finally {
            this.dispatchLoading(false);
        }
    }

    dispatchLoading(isLoading) {
        this.dispatchEvent(new CustomEvent('loading', {
            detail: { isLoading }
        }));
    }

    get isFirstPage() {
        return this.currentPage <= 1;
    }

    get isLastPage() {
        return this.currentPage >= this.totalPages;
    }

    handleNext() {
        if (!this.isLastPage) {
            this.currentPage++;
            this.loadRequests();
        }
    }

    handlePrev() {
        if (!this.isFirstPage) {
            this.currentPage--;
            this.loadRequests();
        }
    }

    async handleDelete(event) {
        const recordId = event.currentTarget.dataset.id;

        try {
            await deleteDutyRequest({ requestId: recordId });
            Toast.show({ label: 'Успешно', message: 'Заявка удалена', variant: 'success' });
            this.loadRequests();
        } catch (e) {
            console.error('Ошибка при удалении заявки', e);
            Toast.show({ label: 'Ошибка', message: 'Не удалось удалить заявку', variant: 'error' });
        }
    }

    isDeleteDisabled(item) {
        // Replace this condition later with your business logic
        // return item.Status__c !== 'Ожидает';
        return false;
    }
}
