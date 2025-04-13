public without sharing class AccomodationSettingsController implements Metadata.DeployCallback {
    @AuraEnabled
    public static void updateAccomodationSetting(Boolean isActive) {
        try {
            Accommodation_Setting__mdt tcm = getExistingRecords()[0];

            Metadata.CustomMetadata customMetadataRecord = new Metadata.CustomMetadata();
            customMetadataRecord.fullName = 'Accommodation_Setting.Default_Setting';
            customMetadataRecord.label = 'Default_Setting';

            Metadata.CustomMetadataValue statusField = new Metadata.CustomMetadataValue();
            statusField.field = 'Is_Registration_Active__c';
            statusField.value = isActive;
            customMetadataRecord.values.add(statusField);
            
            Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            mdContainer.addMetadata(customMetadataRecord);
            
            AccomodationSettingsController callback = new AccomodationSettingsController();
            
            Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        } catch (Exception e) {
            LOGGER.error('Error when enabling accomodation: ' + e.getMessage());
            LOGGER.saveLog();
            throw new AccomodationSettingException(e);
        }
    }

    public static List<Accommodation_Setting__mdt> getExistingRecords()
    {
        List<Accommodation_Setting__mdt> tcm = [SELECT Id, Is_Registration_Active__c FROM Accommodation_Setting__mdt];
        return tcm;
    }

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if(result.status == Metadata.DeployStatus.SUCCEEDED) {
            LOGGER.info('Accomodation setting was deployed successfully!');
        } else {
            LOGGER.error('Error when enabling accomodation. Check Deployment Status for details');
        }

        LOGGER.saveLog();
    }

    @AuraEnabled
    public static Boolean getRegistrationStatus() {
        List<Accommodation_Setting__mdt> settings = getExistingRecords();
        return !settings.isEmpty() && settings[0].Is_Registration_Active__c;
    }

    public class AccomodationSettingException extends Exception {}
}