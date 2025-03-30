import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ConfirmationModal extends LightningModal {
    @api title = 'Подтверждение';
    @api message = 'Вы уверены?';
    @api confirmLabel = 'OK';
    @api cancelLabel = 'Отмена';

    handleConfirm() {
        this.close('confirm');
    }

    handleCancel() {
        this.close(null);
    }
}
