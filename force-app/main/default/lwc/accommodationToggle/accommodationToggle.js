import { LightningElement } from 'lwc';
import getRegistrationStatus from '@salesforce/apex/AccomodationSettingsController.getRegistrationStatus';
import updateAccomodationSetting from '@salesforce/apex/AccomodationSettingsController.updateAccomodationSetting';

export default class AccommodationToggle extends LightningElement {
    isActive = false;

    isLoading = false;
    error = undefined;

    connectedCallback() {
        this.fetchRegistrationStatus();
    }

    async fetchRegistrationStatus() {
        this.isLoading = true;

        try {
            this.isActive = getRegistrationStatus();
            this.error = undefined;
        } catch (error) {
            this.error = error.body.message;
            this.isActive = false;
        } finally {
            this.isLoading = false;
        }
    }

    handleToggle(event) {
        this.isActive = event.target.checked;
        this.updateAccomodationSettingStatus();
    }

    async updateAccomodationSettingStatus() {
        this.isLoading = true;

        try {
            await updateAccomodationSetting({ 
                isActive: this.isActive 
            });

            this.error = undefined;
        } catch (error) {
            this.error = error.body.message;
        } finally {
            this.isLoading = false;
        }
    }
}
