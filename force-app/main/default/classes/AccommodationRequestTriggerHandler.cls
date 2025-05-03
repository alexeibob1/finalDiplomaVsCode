public without sharing class AccommodationRequestTriggerHandler extends TriggerHandler {
    private Map<Id, Accomodation_Request__c> newMap;
    private Map<Id, Accomodation_Request__c> oldMap;
    private List<Accomodation_Request__c> newList;

    public AccommodationRequestTriggerHandler() {
        this.newMap = (Map<Id, Accomodation_Request__c>) Trigger.newMap;
        this.oldMap = (Map<Id, Accomodation_Request__c>) Trigger.oldMap;
        this.newList = (List<Accomodation_Request__c>) Trigger.new;
    }

    public override void afterUpdate() {
        handleSettledStatus();
        handleEvictedStatus();
    }

    private void handleSettledStatus() {
        List<Accomodation_Request__c> newlySettled = getNewlySettledRequests();
        if (newlySettled.isEmpty()) return;

        Set<Id> roomIds = new Set<Id>();
        Set<Id> studentIds = new Set<Id>();
        for (Accomodation_Request__c req : newlySettled) {
            roomIds.add(req.Room__c);
            studentIds.add(req.Student_Contact__c);
        }

        Map<Id, Room__c> rooms = getRoomsWithParent(roomIds);
        Map<Id, Contact> students = getStudentsWithSex(studentIds);
        AccountSharingService.shareDormitoryAccountsWithStudents(students.values());

        List<Room__c> roomsToUpdate = new List<Room__c>();

        for (Accomodation_Request__c req : newlySettled) {
            Room__c room = rooms.get(req.Room__c);
            Contact student = students.get(req.Student_Contact__c);
            String studentSex = student.Sex__c;

            if (room.Sex__c == null) {
                Integer currentOccupants = [
                    SELECT COUNT()
                    FROM Accomodation_Request__c
                    WHERE Room__c = :room.Id AND Status__c = 'Заселен'
                ];

                if (currentOccupants == 1) {
                    room.Sex__c = studentSex;
                    roomsToUpdate.add(room);

                    if (room.Parent_Room__c != null) {
                        Room__c parentRoom = rooms.get(room.Parent_Room__c);
                        if (parentRoom != null) {
                            parentRoom.Sex__c = studentSex;
                            roomsToUpdate.add(parentRoom);

                            for (Room__c sibling : rooms.values()) {
                                if (sibling.Parent_Room__c == room.Parent_Room__c && sibling.Id != room.Id) {
                                    sibling.Sex__c = studentSex;
                                    roomsToUpdate.add(sibling);
                                }
                            }
                        }
                    }
                }
            }
        }

        if (!roomsToUpdate.isEmpty()) {
            update roomsToUpdate;
        }
    }

    private void handleEvictedStatus() {
        List<Accomodation_Request__c> evictedRequests = getNewlyEvictedRequests();
        if (evictedRequests.isEmpty()) {
            return;
        }

        Set<Id> roomIds = new Set<Id>();
        Set<Id> studentIds = new Set<Id>();

        for (Accomodation_Request__c req : evictedRequests) {
            if (req.Room__c != null) {
                roomIds.add(req.Room__c);
            }
            if (req.Student_Contact__c != null) {
                studentIds.add(req.Student_Contact__c);
            }
        }

        Map<Id, Room__c> rooms = getRoomsWithParent(roomIds);
        Map<Id, Contact> students = getStudentsById(studentIds);

        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact contact : students.values()) {
            contactsToUpdate.add(new Contact(
                Id = contact.Id,
                Room__c = null
            ));
        }

        AccountSharingService.removeDormitoryAccountShares(students.values());

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate;
        }

        for (Accomodation_Request__c req : evictedRequests) {
            if (req.Room__c != null && rooms.containsKey(req.Room__c)) {
                Room__c r = rooms.get(req.Room__c);
                if (r.Available_Places__c == null) {
                    r.Available_Places__c = 1;
                } else {
                    r.Available_Places__c += 1;
                }

                if (r.Room_Leader__c != null && studentIds.contains(r.Room_Leader__c)) {
                    r.Room_Leader__c = null;
                }
            }
        }

        Set<Id> parentRoomIdsToClear = new Set<Id>();
        Map<Id, Room__c> allRoomsToClearSexMap = new Map<Id, Room__c>();

        for (Room__c room : rooms.values()) {
            Integer stillOccupied = [
                SELECT COUNT()
                FROM Accomodation_Request__c
                WHERE Room__c = :room.Id AND Status__c = 'Заселен'
            ];

            if (stillOccupied == 0) {
                room.Sex__c = null;
                allRoomsToClearSexMap.put(room.Id, room);

                if (room.Parent_Room__c != null) {
                    parentRoomIdsToClear.add(room.Parent_Room__c);
                }
            }
        }

        if (!parentRoomIdsToClear.isEmpty()) {
            List<Room__c> related = [
                SELECT Id, Sex__c
                FROM Room__c
                WHERE Id IN :parentRoomIdsToClear OR Parent_Room__c IN :parentRoomIdsToClear
            ];
            for (Room__c r : related) {
                r.Sex__c = null;
                allRoomsToClearSexMap.put(r.Id, r);
            }
        }

        if (!rooms.isEmpty()) {
            update rooms.values();
        }

        if (!allRoomsToClearSexMap.isEmpty()) {
            update allRoomsToClearSexMap.values(); 
        }
    }

    private List<Accomodation_Request__c> getNewlySettledRequests() {
        List<Accomodation_Request__c> result = new List<Accomodation_Request__c>();
        for (Accomodation_Request__c req : newList) {
            Accomodation_Request__c oldReq = oldMap.get(req.Id);
            if (req.Status__c == 'Заселен' &&
                oldReq.Status__c != 'Заселен' &&
                req.Room__c != null &&
                req.Student_Contact__c != null) {
                result.add(req);
            }
        }
        return result;
    }

    private List<Accomodation_Request__c> getNewlyEvictedRequests() {
        List<Accomodation_Request__c> result = new List<Accomodation_Request__c>();
        for (Accomodation_Request__c req : newList) {
            Accomodation_Request__c oldReq = oldMap.get(req.Id);
            if (req.Status__c == 'Выселен' &&
                oldReq.Status__c != 'Выселен' &&
                req.Room__c != null) {
                result.add(req);
            }
        }
        return result;
    }

    private Map<Id, Room__c> getRoomsWithParent(Set<Id> roomIds) {
        Set<Id> allRoomIds = new Set<Id>(roomIds);
        Map<Id, Room__c> rooms = new Map<Id, Room__c>();

        List<Room__c> queried = [
            SELECT Id, Sex__c, Parent_Room__c, Available_Places__c, Room_Leader__c
            FROM Room__c
            WHERE Id IN :roomIds
        ];

        for (Room__c r : queried) {
            rooms.put(r.Id, r);
            if (r.Parent_Room__c != null) {
                allRoomIds.add(r.Parent_Room__c);
            }
        }

        List<Room__c> parentsAndSiblings = [
            SELECT Id, Sex__c, Parent_Room__c, Available_Places__c, Room_Leader__c
            FROM Room__c
            WHERE Id IN :allRoomIds OR Parent_Room__c IN :allRoomIds
        ];

        for (Room__c r : parentsAndSiblings) {
            rooms.put(r.Id, r);
        }

        return rooms;
    }

    private Map<Id, Contact> getStudentsWithSex(Set<Id> studentIds) {
        return new Map<Id, Contact>([
            SELECT Id, Sex__c
            FROM Contact
            WHERE Id IN :studentIds
        ]);
    }

    private Map<Id, Contact> getStudentsById(Set<Id> studentIds) {
        return new Map<Id, Contact>([
            SELECT Id
            FROM Contact
            WHERE Id IN :studentIds
        ]);
    }
}
