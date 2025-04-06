import { LightningElement, api, track } from 'lwc';
import getShiftsForMonthDuty from '@salesforce/apex/DutyController.getShiftsForMonthDuty';
import getRequestsForStudentAndMonth from '@salesforce/apex/DutyController.getRequestsForStudentAndMonth';
import submitDutyRequests from '@salesforce/apex/DutyController.submitDutyRequests';
import Toast from 'lightning/toast';

export default class DutyRequestModal extends LightningElement {
    @api monthDutyId; // full Month_Duty__c record
    @api studentId;

    @track shifts = [];
    @track selectedRequests = new Map(); // key = `${date}-${shiftId}`
    @track existingRequests = new Set(); // prevent duplicates
    @track days = [];

    maxRequests = 5;

    isLoading = true;

    async connectedCallback() {
        await this.loadData();
    }

    async loadData() {
        this.isLoading = true;
        try {
            const [shifts, existing] = await Promise.all([
                getShiftsForMonthDuty({ monthDutyId: this.monthDutyId }),
                getRequestsForStudentAndMonth({ studentId: this.studentId, monthDutyId: this.monthDutyId })
            ]);

            this.shifts = shifts;
            this.generateDays(this.monthDutyId);

            existing.forEach(req => {
                const key = `${req.Duty_Date__c}-${req.Duty_Shift__r?.Name || ''}`;
                this.existingRequests.add(key);
            });
        } catch (err) {
            this.showError('Ошибка загрузки данных: ' + err.body?.message || err.message);
        } finally {
            this.isLoading = false;
        }
    }

    generateDays(baseDateStr) {
        const baseDate = new Date(baseDateStr);
        const year = baseDate.getFullYear();
        const month = baseDate.getMonth(); // 0-based
        const daysInMonth = new Date(year, month + 1, 0).getDate();

        this.days = [];
        for (let i = 1; i <= daysInMonth; i++) {
            const day = new Date(year, month, i);
            this.days.push(day.toISOString().split('T')[0]); // 'YYYY-MM-DD'
        }
    }

    handleCheckboxChange(event) {
        const date = event.target.dataset.date;
        const shiftId = event.target.dataset.shiftId;
        const key = `${date}-${shiftId}`;

        if (event.target.checked) {
            if (this.selectedRequests.size + this.existingRequests.size >= this.maxRequests) {
                event.target.checked = false;
                this.showError(`Нельзя выбрать больше ${this.maxRequests} дат`);
                return;
            }
            this.selectedRequests.set(key, { dutyDate: date, dutyShiftId: shiftId });
        } else {
            this.selectedRequests.delete(key);
        }
    }

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

    isChecked(date, shiftId) {
        const key = `${date}-${shiftId}`;
        return this.selectedRequests.has(key);
    }

    isDisabled(date, shiftName) {
        const key = `${date}-${shiftName}`;
        return this.existingRequests.has(key);
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant, mode: 'dismissible' });
    }
}
