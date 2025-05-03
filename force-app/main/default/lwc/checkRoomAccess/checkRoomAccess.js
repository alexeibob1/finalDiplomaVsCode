import { LightningElement, track } from 'lwc';
import getCurrentUserContact from '@salesforce/apex/StudentDAO.getCurrentUserContact';
import Toast from 'lightning/toast';

export default class CheckRoomAccess extends LightningElement {
    @track isLoading = true;

    async connectedCallback() {
        try {
            const contact = await getCurrentUserContact();

            if (!contact.Room__c) {
                this.showToast(
                    'Доступ ограничен',
                    'Вы будете перенаправлены, так как вы не заселены в общежитие.',
                    'info'
                );

                // eslint-disable-next-line @lwc/lwc/no-async-operation
                window.location.href = '/dormitory/accomodation-requests';
            }
        } catch (e) {
            this.isLoading = false;
            this.showToast('Ошибка', e.body?.message || e.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(label, message, variant = 'info') {
        Toast.show({
            label,
            message,
            variant,
            mode: 'dismissible'
        });
    }
}
