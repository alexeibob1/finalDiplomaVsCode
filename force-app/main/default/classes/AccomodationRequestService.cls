public with sharing class AccomodationRequestService {
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
            
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    }
}
