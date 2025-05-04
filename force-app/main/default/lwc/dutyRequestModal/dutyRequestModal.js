import { api, LightningElement, track } from 'lwc';
import getShiftsForMonthDuty from '@salesforce/apex/DutyController.getShiftsForMonthDuty';
import getRequestsForStudentAndMonth from '@salesforce/apex/DutyController.getRequestsForStudentAndMonth';
import getCurrentRequestCountForMonthDuty from '@salesforce/apex/DutyController.getCurrentRequestCountForMonthDuty';
import submitDutyRequests from '@salesforce/apex/DutyController.submitDutyRequests';
import getMonthDutyById from '@salesforce/apex/DutyController.getMonthDutyById';
import hasExistingRequestsForShift from '@salesforce/apex/DutyController.hasExistingRequestsForShift';
import Toast from 'lightning/toast';
import LightningModal from 'lightning/modal';

export default class DutyRequestModal extends LightningModal {
    @api monthDutyId;
    @api studentId;

    @track showConflictModal = false;

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
    selectedRequest;

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
                getCurrentRequestCountForMonthDuty({ studentId: this.studentId, monthDutyId: this.monthDutyId })
            ]);

            this.shifts = shifts;
            this.requestCount = count;
            this.showRequestLimitWarning = count >= this.maxRequests;

            // Parse base month/year from Duty_Month_Year__c (assume '2025-04' format)
            const [year, month] = monthDuty.Duty_Month_Year__c.split('-').map(Number);
            this.baseDate = new Date(year, month - 1); // JS months are 0-indexed

            // Store existing requests to disable those cells
            existing.forEach(req => {
                const key = `${req.Duty_Date__c}-${req.Month_Duty_Shift__c}`;
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
        return `${year}-${month}-${day}`;
    }

    generateCalendarData(year, month) {
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const rows = [];

    
        for (let day = 1; day <= daysInMonth; day++) {
            const dateObj = new Date(year, month, day);
            const dateISO = this.formatDateLocal(dateObj);
    
            const row = {
                date: dateISO,
                cells: this.shifts.map(shift => {
                    const key = `${dateISO}-${shift.Id}`;
                    return {
                        key,
                        shiftId: shift.Id,
                        disabled: this.existingRequests.has(key),
                        checked: false
                    };
                })
            };
            rows.push(row);
        }

    
        this.calendarData = rows;
    }

    handleRadioChange(event) {
        const { date, shiftId } = event.target.dataset;
        this.isSubmitDisabled = false;
    
        this.selectedRequest = {
            dutyDate: date,
            dutyShiftId: shiftId
        };
    
        // Update calendar UI state
        this.calendarData.forEach(row => {
            row.cells.forEach(cell => {
                cell.checked = (row.date === date && cell.shiftId === shiftId);
            });
        });
    }

    async handleSubmit() {
        if (!this.selectedRequest) {
            this.showError('Выберите смену и дату');
            return;
        }

        const { dutyDate, dutyShiftId } = this.selectedRequest;

        try {
            this.isLoading = true;
            const hasConflict = await hasExistingRequestsForShift({
                dutyDate: dutyDate,
                monthDutyShiftId: dutyShiftId
            });
            if (hasConflict) {
                this.showConflictModal = true;
            } else {
                await this.submitRequest(dutyDate, dutyShiftId);
            }

        } catch (err) {
            console.error(err);
            this.showError(err.body?.message || err.message);
        } finally {
            this.isLoading = false;
        }
    }

    async submitRequest(dutyDate, dutyShiftId) {
        try {
            this.isLoading = true;
            await submitDutyRequests({
                studentId: this.studentId,
                monthDutyId: this.monthDutyId,
                requests: [{ dutyDate, monthDutyShiftId: dutyShiftId }]
            });
    
            this.showSuccess('Заявка успешно отправлена');
            this.dispatchEvent(new CustomEvent('requestsubmitted'));
            this.dispatchEvent(new CustomEvent('close'));
        } catch (err) {
            this.showError(err.body?.message || err.message);
        } finally {
            this.isLoading = false;
            this.close('close');
        }
    }

    handleConflictCancel() {
        this.showConflictModal = false;
    }
    
    async handleConflictConfirm() {
        this.showConflictModal = false;
    
        const { dutyDate, dutyShiftId } = this.selectedRequest;
        await this.submitRequest(dutyDate, dutyShiftId);
    }    

    handleCancel() {
        this.close('close');
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
