import { LightningElement, track } from 'lwc';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';
import getWorkRecordsForCurrentStudent from '@salesforce/apex/SocialUsefulWorkController.getWorkRecordsForCurrentStudent';

export default class StudentHours extends LightningElement {
    @track isLoading = true;
    @track hasError = false;
    @track hours = 0;

    // Table data
    @track records = [];
    @track totalRecords = 0;
    @track pageSize = 5;
    @track pageNumber = 0;

    columns = [
        { label: 'Дата', fieldName: 'Work_Date__c', type: 'date' },
        { label: 'Часы', fieldName: 'Hours__c', type: 'number' },
        {
            label: 'Описание',
            fieldName: 'Work_Type__c',
            type: 'text',
            wrapText: true
        }
    ];

    get hoursText() {
        const form = this.getHourWordForm(this.hours);
        return `В этом учебном году вы выполнили ${this.hours} ${form} общественно полезного труда.`;
    }

    connectedCallback() {
        this.loadStudentData();
    }

    async loadStudentData() {
        this.isLoading = true;
        try {
            const contact = await getCurrentUserContact();
            this.hours = contact.Current_Study_Year_Hours__c || 0;
            await this.loadRecords();
            this.hasError = false;
        } catch (error) {
            console.error('Ошибка при загрузке:', error);
            this.hasError = true;
        } finally {
            this.isLoading = false;
        }
    }

    async loadRecords() {
        this.isLoading = true;
        try {
            const result = await getWorkRecordsForCurrentStudent({ 
                pageSize: this.pageSize, 
                pageNumber: this.pageNumber 
            });
            this.records = result.records;
            this.totalRecords = result.totalRecords;
        } catch (error) {
            console.error('Ошибка при получении списка работ:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handlePrev() {
        if (this.pageNumber > 0) {
            this.pageNumber--;
            this.loadRecords();
        }
    }

    handleNext() {
        if ((this.pageNumber + 1) < this.totalPages) {
            this.pageNumber++;
            this.loadRecords();
        }
    }

    get isFirstPage() {
        return this.pageNumber === 0;
    }
    
    get isLastPage() {
        return this.pageNumber + 1 >= this.totalPages;
    }

    get hasData() {
        return this.totalRecords > 0;
    }

    get totalPages() {
        return this.totalRecords > 0 ? Math.ceil(this.totalRecords / this.pageSize) : 0;
    }
    
    get currentPageDisplay() {
        return this.totalRecords > 0 ? this.pageNumber + 1 : 0;
    }
    

    getHourWordForm(n) {
        n = Math.abs(n);
        if (n % 10 === 1 && n % 100 !== 11) return 'час';
        if ([2, 3, 4].includes(n % 10) && ![12, 13, 14].includes(n % 100)) return 'часа';
        return 'часов';
    }
}
