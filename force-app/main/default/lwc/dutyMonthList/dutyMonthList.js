import { LightningElement, track } from 'lwc';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';
import getAvailableMonthDuties from '@salesforce/apex/DutyController.getAvailableMonthDuties';
import getAvailableMonthDutiesCount from '@salesforce/apex/DutyController.getAvailableMonthDutiesCount';
import DutyModal from 'c/dutyRequestModal';

const actions = [
    { label: 'Записаться', name: 'apply' }
];

const COLUMNS = [
    { label: 'Месяц', fieldName: 'FX_Duty_Month__c' },
    { label: 'Год', fieldName: 'FX_Duty_Year__c' },
    { label: 'Этаж', fieldName: 'Floor__c', type: 'number' },
    // { label: 'Регистрация активна', fieldName: 'Is_Registration_Active__c', type: 'boolean' },
    {
        type: 'action',
        typeAttributes: { rowActions : actions }
    }
];

export default class DutyMonthList extends LightningElement {
    @track duties = [];
    @track columns = COLUMNS;

    studentId;
    pageSize = 10;
    pageNumber = 1;
    totalDuties = 0;
    isLoading = false;

    selectedMonthDutyId = null;
    showModal = false;

    connectedCallback() {
        this.init();
    }

    async init() {
        this.isLoading = true;
        try {
            const contact = await getCurrentUserContact();
            this.studentId = contact?.Id;

            if (this.studentId) {
                await this.loadData();
            }
        } catch (error) {
            console.error('Error retrieving current student:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadData() {
        this.isLoading = true;
        try {
            const [count, duties] = await Promise.all([
                getAvailableMonthDutiesCount({ studentId: this.studentId }),
                getAvailableMonthDuties({
                    studentId: this.studentId,
                    pageNumber: this.pageNumber,
                    pageSize: this.pageSize
                })
            ]);

            this.totalDuties = count;
            this.duties = duties;
        } catch (e) {
            console.error('Error loading duties', e);
        } finally {
            this.isLoading = false;
        }
    }

    get disablePrev() {
        return this.pageNumber <= 1;
    }

    get disableNext() {
        return this.pageNumber * this.pageSize >= this.totalDuties;
    }

    previousPage() {
        if (!this.disablePrev) {
            this.pageNumber--;
            this.loadData();
        }
    }

    nextPage() {
        if (!this.disableNext) {
            this.pageNumber++;
            this.loadData();
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'apply') {
            this.selectedMonthDutyId = row.Id;

            const result = await DutyModal.open({
                size: 'large', 
                studentId: this.studentId,
                monthDutyId: this.selectedMonthDutyId,
                onrequestsubmitted: () => {
                    this.dispatchEvent(new CustomEvent('requestsubmitted'));
                }
            });
        }
    }

    get hasDuties() {
        return this.duties && this.duties.length > 0;
    }

    closeModal() {
        this.showModal = false;
        this.selectedMonthDutyId = null;
    }
}