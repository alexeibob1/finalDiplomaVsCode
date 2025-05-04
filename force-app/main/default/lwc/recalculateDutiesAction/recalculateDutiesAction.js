import { LightningElement, api } from 'lwc';
import recalculateSingleStudent from '@salesforce/apex/RecalculateDutyRequestsActionController.recalculateSingleStudent';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

export default class RecalculateDutiesAction extends LightningElement {
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
                    message: 'Дежурства успешно пересчитаны.',
                    variant: 'success'
                })
            );

            notifyRecordUpdateAvailable([{'recordId': this.recordId}]);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Ошибка',
                    message: error?.body?.message || 'Ошибка при пересчете количества дежурств.',
                    variant: 'error'
                })
            );
        } finally {
            this.isExecuting = false;
        }
    }
}