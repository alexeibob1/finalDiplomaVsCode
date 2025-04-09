import { LightningElement, track, wire } from 'lwc';
import getStudentContext from '@salesforce/apex/MaintenanceRequestController.getStudentContext';
import getRoomsForDormitory from '@salesforce/apex/MaintenanceRequestController.getRoomsForDormitory';
import createMaintenanceRequest from '@salesforce/apex/MaintenanceRequestController.createMaintenanceRequest';

import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import MAINTENANCE_OBJECT from '@salesforce/schema/Maintenance_Request__c';
import TYPE_FIELD from '@salesforce/schema/Maintenance_Request__c.Type__c';

export default class MaintenanceRequestForm extends LightningElement {
    @track typeOptions = [];
    @track roomOptions = [];

    type = '';
    description = '';
    commonArea = '';
    roomId = '';
    roomName = '';
    studentId = '';
    dormitoryId = '';
    gender = '';

    showRoomSelection = false;
    isCommonArea = false;

    recordTypeId;

    @wire(getObjectInfo, { objectApiName: MAINTENANCE_OBJECT })
    objectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        }
        if (error) {
            console.error(error?.body?.message);
        }
    }

    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredPicklist({ data, error }) {
        if (data) {
            this.typeOptions = data.values;
        } else {
            console.error(error?.body?.message);
        }
    }

    async connectedCallback() {
        try {
            const context = await getStudentContext();
            this.roomId = context.roomId;
            this.studentId = context.studentId;
            this.dormitoryId = context.dormitoryId;
            this.gender = context.gender;
            this.roomName = context.roomName;

            const rooms = await getRoomsForDormitory({dormitoryId: this.dormitoryId});
            this.roomOptions = rooms.map(room => ({
                label: room.Name,
                value: room.Id
            }));
        } catch (err) {
            console.error('Ошибка при инициализации:', err);
        }
    }

    handleChange(event) {
        const { name, value } = event.target;
        this[name] = value;
    }

    toggleRoomEdit() {
        this.showRoomSelection = !this.showRoomSelection;
    }

    toggleCommonArea() {
        this.isCommonArea = !this.isCommonArea;
    }

    async handleSubmit() {
        if (!this.type || !this.description || (this.isCommonArea && !this.commonArea) || (!this.isCommonArea && !this.roomId)) {
            return;
        }

        const payload = {
            studentId: this.studentId,
            roomId: this.roomId,
            description: this.description,
            type: this.type,
            dormitoryId: this.dormitoryId,
            commonArea: this.isCommonArea ? this.commonArea : ''
        };

        try {
            await createMaintenanceRequest( payload );
        } catch (error) {
            console.error('Ошибка при создании заявки:', error);
        }
    }
}
