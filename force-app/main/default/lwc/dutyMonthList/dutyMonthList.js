import { LightningElement, track } from 'lwc';
import getCurrentUserAccount from '@salesforce/apex/StudentDAO.getCurrentUserAccount';
import getAvailableMonthDuties from '@salesforce/apex/DutyController.getAvailableMonthDuties';
import getAvailableMonthDutiesCount from '@salesforce/apex/DutyController.getAvailableMonthDutiesCount';

const actions = [
    { label: 'Записаться', name: 'apply' }
];

const COLUMNS = [
    { label: 'Месяц', fieldName: 'FX_Duty_Month__c' },
    { label: 'Год', fieldName: 'FX_Duty_Year__c' },
    { label: 'Этаж', fieldName: 'Floor__c', type: 'number' },
    { label: 'Регистрация активна', fieldName: 'Is_Registration_Active__c', type: 'boolean' },
    {
        type: 'action',
        typeAttributes: { rowActions : actions }
    }
];

export default class DutyMonthList extends LightningElement {
    @track duties = [];
    @track columns = COLUMNS;

    accountId;
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
            const account = await getCurrentUserAccount();
            this.accountId = account?.Id;

            if (this.accountId) {
                await this.loadData();
            }
        } catch (error) {
            console.error('Error retrieving current user account:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadData() {
        this.isLoading = true;
        try {
            const [count, duties] = await Promise.all([
                getAvailableMonthDutiesCount({ studentAccountId: this.accountId }),
                getAvailableMonthDuties({
                    studentAccountId: this.accountId,
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

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'apply') {
            this.selectedMonthDutyId = row.Id;
            this.showModal = true;
        }
    }

    closeModal() {
        this.showModal = false;
        this.selectedMonthDutyId = null;
    }
}