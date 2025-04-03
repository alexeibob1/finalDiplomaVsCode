import { LightningElement, api, track } from 'lwc';
import getAvailableRooms from '@salesforce/apex/RoomSelectionController.getAvailableRooms';
import getTotalRoomsCount from '@salesforce/apex/RoomSelectionController.getTotalRoomsCount';
import getStudent from '@salesforce/apex/StudentDAO.getAccountByAccomodationRequestId';

const COLUMNS = [
    { label: 'Комната', fieldName: 'Name' },
    { label: 'Общежитие', fieldName: 'DormitoryName' },
    { label: 'Свободных мест', fieldName: 'Available_Places__c', type: 'number' },
    { label: 'Вместимость', fieldName: 'Capacity__c', type: 'number' },
    { type: 'button', typeAttributes: { label: 'Выбрать', name: 'select', variant: 'brand' } }
];

export default class RoomSelection extends LightningElement {
    @api recordId;
    @track rooms = [];
    columns = COLUMNS;
    
    studentRecord = null;
    pageNumber = 1;
    pageSize = 10;
    totalRooms = 0;
    isLoading = false;

    async connectedCallback() {
        await this.reloadData();
    }

    async fetchStudent() {
        this.isLoading = true;
        try {
            this.studentRecord = await getStudent({ requestId: this.recordId });
        } catch (error) {
            console.error(error);
        } finally {
            this.isLoading = false;
        }
    }

    async loadRooms() {
        if (!this.studentRecord) return;

        this.isLoading = true;
        try {
            const studentGender = this.studentRecord.PersonContact.Sex__c;
            this.totalRooms = await getTotalRoomsCount({ studentGender });
            this.rooms = (await getAvailableRooms({ studentGender, pageNumber: this.pageNumber, pageSize: this.pageSize }))
                .map(room => ({
                    ...room,
                    DormitoryName: room.Dormitory__r?.Name || 'Не указано'
                }));
        } catch (error) {
            console.error('Error loading rooms:', error);
        } finally {
            this.isLoading = false;
        }
    }

    async reloadData() {
        this.isLoading = true;
        try {
            await this.fetchStudent();
            await this.loadRooms();
        } finally {
            this.isLoading = false;
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
