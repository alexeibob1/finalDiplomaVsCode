public without sharing class AccomodationRequestService {
    public static void sendStatusUpdateEmails(List<Accomodation_Request__c> requests) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        for (Accomodation_Request__c request : requests) {
            System.debug('in call ' + request.Student__r);
            if (String.isEmpty(request.Student__r.PersonEmail)) {
                System.debug('no email');
                continue;
            }

            String subject = 'Статус заявки на заселение изменен';
            String body = 'Здравствуйте, ' + request.FX_Student_Name__c + '!\n\n' +
                          'Ваша заявка ' + request.Name + 
                          ' на проживание в общежитии была переведена в статус "' + request.Status__c + '".';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ request.Student__r.PersonEmail });
            email.setSubject(subject);
            email.setPlainTextBody(body);
            email.setSaveAsActivity(false);
            email.setTreatTargetObjectAsRecipient(false);
            
            emails.add(email);
        }

        System.debug('emails size: ' + emails.size() + ', ' + emails[0]);
        if (!emails.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);
            System.debug('results ' + results);
        }
    }

    @future(callout=false)
    public static void sendStatusUpdateEmailsAsync(List<Id> requestIds) {
        List<Accomodation_Request__c> requestsToSendEmail = [
            SELECT Id, Name, toLabel(Status__c), FX_Student_Name__c, 
                Student__r.PersonEmail  
            FROM Accomodation_Request__c
            WHERE Id IN :requestIds
        ];

        sendStatusUpdateEmails(requestsToSendEmail);
    }
}
