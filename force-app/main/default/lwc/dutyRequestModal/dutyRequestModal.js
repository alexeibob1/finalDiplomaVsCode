import { api, LightningElement, track } from 'lwc';
import getShiftsForMonthDuty from '@salesforce/apex/DutyController.getShiftsForMonthDuty';
import getRequestsForStudentAndMonth from '@salesforce/apex/DutyController.getRequestsForStudentAndMonth';
import getCurrentRequestCountForMonthDuty from '@salesforce/apex/DutyController.getCurrentRequestCountForMonthDuty';
import submitDutyRequests from '@salesforce/apex/DutyController.submitDutyRequests';
import getMonthDutyById from '@salesforce/apex/DutyController.getMonthDutyById';
import Toast from 'lightning/toast';

export default class DutyRequestModal extends LightningElement {
    @api monthDutyId;
    @api studentId;

    @track shifts = [];
    @track calendarData = [];
    @track existingRequests = new Set();
    @track selectedKey = null;

    @track showRequestLimitWarning = false;
    @track isSubmitDisabled = true;

    isLoading = true;
    maxRequests = 5;
    requestCount = 0;
    baseDate;

    async connectedCallback() {
        await this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const [monthDuty, shifts, existing, count] = await Promise.all([
                getMonthDutyById({ monthDutyId: this.monthDutyId }),
                getShiftsForMonthDuty({ monthDutyId: this.monthDutyId }),
                getRequestsForStudentAndMonth({ studentId: this.studentId, monthDutyId: this.monthDutyId }),
                getCurrentRequestCountForMonthDuty({ studentAccountId: this.studentId, monthDutyId: this.monthDutyId })
            ]);

            this.shifts = shifts;
            this.requestCount = count;
            this.showRequestLimitWarning = count >= this.maxRequests;

            // Parse base month/year from Duty_Month_Year__c (assume '2025-04' format)
            const [year, month] = monthDuty.Duty_Month_Year__c.split('-').map(Number);
            this.baseDate = new Date(year, month - 1); // JS months are 0-indexed

            // Store existing requests to disable those cells
            existing.forEach(req => {
                const key = `${req.Duty_Date__c}-${req.Duty_Shift__c}`;
                this.existingRequests.add(key);
            });

            this.generateCalendarData(year, month - 1);
        } catch (err) {
            this.showError('Ошибка загрузки данных: ' + (err.body?.message || err.message));
        } finally {
            this.isLoading = false;
        }
    }

    formatDateLocal(date) {
        const year = date.getFullYear();
        const month = (date.getMonth() + 1).toString().padStart(2, '0');
        const day = date.getDate().toString().padStart(2, '0');
        return `${day}-${month}-${year}`;
    }

    generateCalendarData(year, month) {
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const rows = [];
    
        for (let day = 1; day <= daysInMonth; day++) {
            const dateObj = new Date(year, month, day);
            const dateISO = this.formatDateLocal(dateObj); // <-- Local formatting
    
            const row = {
                date: dateISO,
                cells: this.shifts.map(shift => {
                    const key = `${dateISO}-${shift.Id}`;
                    return {
                        key,
                        shiftId: shift.Id,
                        checked: this.selectedKey === key,
                        disabled: this.existingRequests.has(key)
                    };
                })
            };
            rows.push(row);
        }
    
        this.calendarData = rows;
    }

    handleRadioChange(event) {
        const selectedKey = event.target.dataset.key;
        this.selectedKey = selectedKey;
        this.isSubmitDisabled = false;

        // Update UI states
        this.calendarData.forEach(row => {
            row.cells.forEach(cell => {
                cell.checked = (cell.key === selectedKey);
            });
        });
    }

    async handleSubmit() {
        if (!this.selectedKey) {
            this.showError('Выберите смену и дату');
            return;
        }

        const [dutyDate, dutyShiftId] = this.selectedKey.split('-');

        try {
            this.isLoading = true;
            await submitDutyRequests({
                studentId: this.studentId,
                monthDutyId: this.monthDutyId,
                requests: [{ dutyDate, dutyShiftId }]
            });

            this.showSuccess('Заявка успешно отправлена');
            this.dispatchEvent(new CustomEvent('close'));
        } catch (err) {
            this.showError(err.body?.message || err.message);
        } finally {
            this.isLoading = false;
        }
    }

    

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showSuccess(message) {
        this.showToast('Успешно', message, 'success');
    }

    showError(message) {
        this.showToast('Ошибка', message, 'error');
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant, mode: 'dismissible' });
    }
}
