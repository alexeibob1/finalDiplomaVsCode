import { LightningElement, api, track } from 'lwc';
import getAvailableRooms from '@salesforce/apex/RoomSelectionController.getAvailableRooms';
import getTotalRoomsCount from '@salesforce/apex/RoomSelectionController.getTotalRoomsCount';
import getStudent from '@salesforce/apex/StudentDAO.getAccountByAccomodationRequestId';
import updateAccomodationRequestRoom from '@salesforce/apex/AccomodationRequestController.updateAccomodationRequestRoom';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
    { label: 'Комната', fieldName: 'roomUrl', type: 'url', 
      typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },

    { label: 'Общежитие', fieldName: 'dormitoryUrl', type: 'url', 
      typeAttributes: { label: { fieldName: 'DormitoryName' }, target: '_blank' } },

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
                    roomUrl: `/${room.Id}`,  // Create URL for Room__c
                    dormitoryUrl: room.Dormitory__r ? `/${room.Dormitory__r.Id}` : '', // Create URL for Dormitory (Account)
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

    async handleRowSelection(event) {
        const selectedRoomId = event.detail.row.Id;

        if (!this.recordId) {
            console.error('No request ID provided.');
            return;
        }

        this.isLoading = true;
        try {
            await updateAccomodationRequestRoom({ requestId: this.recordId, roomId: selectedRoomId });
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Успех',
                    message: 'Комната успешно выбрана!',
                    variant: 'success'
                })
            );

            await this.reloadData(); // Refresh the table
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Ошибка',
                    message: 'Ошибка при выборе комнаты: ' + error.body.message,
                    variant: 'error'
                })
            );
            console.error(error);
        } finally {
            this.isLoading = false;
        }
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
