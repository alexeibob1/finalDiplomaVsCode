import { LightningElement, api, track } from 'lwc';
import getAvailableRooms from '@salesforce/apex/RoomSelectionController.getAvailableRooms';
import getTotalRoomsCount from '@salesforce/apex/RoomSelectionController.getTotalRoomsCount';
import getStudent from '@salesforce/apex/StudentDAO.getAccountByAccomodationRequestId';

const COLUMNS = [
    { label: 'Комната', fieldName: 'Name' },
    { label: 'Общежитие', fieldName: 'DormitoryName' },
    { label: 'Свободных мест', fieldName: 'Available_Places__c', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Выбрать', name: 'select', variant: 'brand' } }
];

export default class RoomSelection extends LightningElement {
    @api recordId;

    studentRecord = null;

    @track rooms = [];
    columns = COLUMNS;
    
    pageNumber = 1;
    pageSize = 10;
    totalRooms = 0;

    async connectedCallback() {
        console.log('recordId', this.recordId);
        await this.fetchStudent();
        await this.loadRooms();
    }

    async fetchStudent() {
        try {
            this.studentRecord = await getStudent({ requestId: this.recordId });
            console.log('student', this.studentRecord);
        } catch (error) {
            console.error(error);
        }
    }

    async loadRooms() {
        if (!this.studentRecord) return;
        
        try {
            const studentGender = this.studentRecord.PersonContact.Sex__c;
            this.totalRooms = await getTotalRoomsCount({ studentGender });
            console.log('total rooms', this.totalRooms);
            this.rooms = (await getAvailableRooms({ studentGender, pageNumber: this.pageNumber, pageSize: this.pageSize }))
                .map(room => ({
                    ...room,
                    DormitoryName: room.Dormitory__r?.Name || 'Не указано'
                }));

            console.log('rooms', this.rooms);
        } catch (error) {
            console.error('Error loading rooms:', error);
        }
    }

    handleRowSelection(event) {
        const selectedRoomId = event.detail.row.Id;
        this.dispatchEvent(new CustomEvent('roomselected', { detail: { roomId: selectedRoomId } }));
    }

    get disablePrev() {
        return this.pageNumber === 1;
    }

    get disableNext() {
        return this.pageNumber * this.pageSize >= this.totalRooms;
    }

    async previousPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            await this.loadRooms();
        }
    }

    async nextPage() {
        if (this.pageNumber * this.pageSize < this.totalRooms) {
            this.pageNumber++;
            await this.loadRooms();
        }
    }
}
