import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';
import getShiftsForMonthDuty from '@salesforce/apex/DutyController.getShiftsForMonthDuty';
import getRequestsForStudentAndMonth from '@salesforce/apex/DutyController.getRequestsForStudentAndMonth';
import submitDutyRequests from '@salesforce/apex/DutyController.submitDutyRequests';
import getCurrentRequestCountForMonthDuty from '@salesforce/apex/DutyController.getCurrentRequestCountForMonthDuty';
import Toast from 'lightning/toast';

export default class DutyRequestModal extends LightningModal {
    @api monthDutyId; // Month_Duty__c ID
    @api studentId;

    @track shifts = [];
    @track selectedRequests = new Map(); // key = `${date}-${shiftId}`
    @track existingRequests = new Set(); // to prevent duplicate selections
    @track calendarData = []; // Internal data structure to hold day-shift states
    @track maxRequests = 5; // Max allowed requests
    @track requestCount = 0; // Number of requests the student already has
    @track showRequestLimitWarning = false; // Flag to show/hide warning
    isLoading = true;

    // Fetch Month_Duty record and current requests when component is initialized
    async connectedCallback() {
        await this.loadData();
    }

    // Load shifts and current requests
    async loadData() {
        this.isLoading = true;
        try {
            const [shifts, existing, requestCount] = await Promise.all([
                getShiftsForMonthDuty({ monthDutyId: this.monthDutyId }),
                getRequestsForStudentAndMonth({ studentId: this.studentId, monthDutyId: this.monthDutyId }),
                getCurrentRequestCountForMonthDuty({ studentAccountId: this.studentId, monthDutyId: this.monthDutyId })
            ]);

            // Save data to internal state
            this.shifts = shifts;
            this.requestCount = requestCount;
            this.showRequestLimitWarning = this.requestCount >= this.maxRequests;

            // Generate calendar days and corresponding shifts
            this.generateCalendarData(shifts);

            // Store existing requests to prevent duplicates
            existing.forEach(req => {
                const key = `${req.Duty_Date__c}-${req.Duty_Shift__r?.Name || ''}`;
                this.existingRequests.add(key);
            });
        } catch (err) {
            this.showError('Ошибка загрузки данных: ' + (err.body?.message || err.message));
        } finally {
            this.isLoading = false;
        }
    }

    // Generate calendar data that holds the state for each day-shift combination
    generateCalendarData(shifts) {
        const year = new Date().getFullYear();
        const month = new Date().getMonth();
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        this.calendarData = [];
        
        for (let i = 1; i <= daysInMonth; i++) {
            const day = new Date(year, month, i).toISOString().split('T')[0]; // 'YYYY-MM-DD'
            shifts.forEach(shift => {
                // For each day, create an object with shift data
                const key = `${day}-${shift.Id}`;
                this.calendarData.push({
                    date: day,
                    shiftId: shift.Id,
                    shiftName: shift.Duty_Shift__r?.Name,
                    checked: this.selectedRequests.has(key), // Is checked
                    disabled: this.existingRequests.has(key), // Is disabled (if already requested)
                    key: key
                });
            });
        }
    }

    // Handle checkbox change (select/deselect shift)
    handleCheckboxChange(event) {
        const { date, shiftId } = event.target.dataset;
        const key = `${date}-${shiftId}`;

        if (this.requestCount >= this.maxRequests && event.target.checked) {
            event.target.checked = false;
            this.showError(`Нельзя выбрать больше ${this.maxRequests} дат.`);
            return;
        }

        const index = this.calendarData.findIndex(item => item.key === key);
        if (index !== -1) {
            this.calendarData[index].checked = event.target.checked;
            if (event.target.checked) {
                this.selectedRequests.set(key, { dutyDate: date, dutyShiftId: shiftId });
            } else {
                this.selectedRequests.delete(key);
            }
        }
    }

    // Handle form submission
    async handleSubmit() {
        if (this.selectedRequests.size === 0) {
            this.showError('Выберите хотя бы одну дату');
            return;
        }

        const requests = Array.from(this.selectedRequests.values());

        try {
            this.isLoading = true;
            await submitDutyRequests({
                studentId: this.studentId,
                monthDutyId: this.monthDutyId,
                requests: requests
            });
            this.showSuccess('Заявки успешно отправлены');
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

    // Check if the shift is already selected
    isChecked(day, shiftId) {
        const key = `${day}-${shiftId}`;
        return this.selectedRequests.has(key);
    }

    // Check if the shift is disabled (already selected or not available)
    isDisabled(day, shiftId) {
        const key = `${day}-${shiftId}`;
        return this.existingRequests.has(key);
    }
}
