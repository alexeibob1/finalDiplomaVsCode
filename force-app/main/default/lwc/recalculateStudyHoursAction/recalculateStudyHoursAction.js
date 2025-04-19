import { LightningElement, api } from 'lwc';
import recalculateSingleStudent from '@salesforce/apex/RecalculateStudyHoursActionController.recalculateSingleStudent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class RecalculateStudyHoursAction extends LightningElement {
    @api recordId;
    isExecuting = false;

    @api async invoke() {
        if (this.isExecuting) return;
        this.isExecuting = true;

        try {
            await recalculateSingleStudent({ accountId: this.recordId });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Успех',
                    message: 'Часы успешно пересчитаны.',
                    variant: 'success'
                })
            );

            notifyRecordUpdateAvailable([{'recordId': this.recordId}]);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Ошибка',
                    message: error?.body?.message || 'Ошибка при пересчете часов.',
                    variant: 'error'
                })
            );
        } finally {
            this.isExecuting = false;
        }
    }
}
