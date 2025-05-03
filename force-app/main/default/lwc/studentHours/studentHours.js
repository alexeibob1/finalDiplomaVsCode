import { LightningElement, track } from 'lwc';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';

export default class StudentHours extends LightningElement {
    @track isLoading = true;
    @track hours = 0;
    @track hasError = false;

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
            this.hasError = false;
        } catch (error) {
            console.error('Error fetching contact:', error);
            this.hasError = true;
        } finally {
            this.isLoading = false;
        }
    }

    getHourWordForm(n) {
        n = Math.abs(n);
        if (n % 10 === 1 && n % 100 !== 11) {
            return 'час';
        } else if ([2, 3, 4].includes(n % 10) && ![12, 13, 14].includes(n % 100)) {
            return 'часа';
        }

        return 'часов';
    }
}
