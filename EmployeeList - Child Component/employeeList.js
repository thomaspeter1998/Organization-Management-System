import { LightningElement, track, api, wire} from 'lwc';

import getEmployees from '@salesforce/apex/EmployeeController.getEmployees';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import getContentVersionId from '@salesforce/apex/EmployeeController.getLatestContentVersionId';
import getFullBranches from '@salesforce/apex/BranchController.getFullBranches';
import transferEmployee from '@salesforce/apex/EmployeeUpdater.transferEmployee';
import deleteEmployee from '@salesforce/apex/EmployeeUpdater.deleteEmployee';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    {
        label: 'Employee Name',
        fieldName: 'Name',
        type: 'button',
        typeAttributes: {
            label: { fieldName: 'Name' },
            name: 'view_details',
            variant: 'base',
            class: 'slds-text-link'
        }
    },
    { label: 'Position', fieldName: 'Position__c'},
    { label: 'Phone Number', fieldName: 'Phone_Number__c'}
];

export default class EmployeeList extends LightningElement {

    @api branchId;
    @api recordId;
    @track employees = [];
    @track employeePopup = false;
    @track columns = COLUMNS;
    @track employeePopup = false;
    @track addEmployeePopup = false;
    @track newEmployeeId = '';
    @track selectedEmployeeId;
    @track contentId;
    @track showEmployeeDetails = false;
    @track employeeImageField = '';
    @track employeeTransfer = false;
    @track fullBranches = [];
    @track error;
    @track targetBranchId;
    @track imageUrl;
    @track deletePopup = false;
    constBId;

    @wire(getEmployees, {Id : '$branchId'})
    wiredEmployees( result ) {
        this.constBId = this.branchId;
        if(result.data) {
            this.employees = result.data;
            this.error = undefined;
            this.employeePopup = true;
        }
        else if(result.error) {
            this.error = result.error;
            this.employees = [];
        }

    }

    @wire(getFullBranches, { Id : '$recordId' , branchId : '$branchId'})
    wiredFullBranches({error, data}) {
        if(data) {
            console.log('full branches:', data);
            this.fullBranches = data.map(branch => ({
                value: branch.Id,
                label: branch.Name,
        }));
            error = undefined;
        }
        else if(error) {
            this.error = error;
            this.fullBranches = [];
        }
    }

    // connectedCallback() {
    //     console.log('branchid=', this.branchId);
    //     getEmployees({Id : this.branchId})
    //     .then(result => {
    //         this.employees = result;
    //         //console.log(JSON.stringify(this.employees))
    //         this.branchId = '';
    //     })
    //     .catch(error => {
    //         console.log(error);
    //         this.employees = [];
    //     });
    //     this.employeePopup = true;
    // }

    closeEmployeePopup() {
        this.employeePopup = false;
        this.dispatchEvent(new CustomEvent('close'));
        return refreshApex(this.constBId);
    }
    handleSuccess(event) {
        this.newEmployeeId = event.detail.id;
        console.log(this.newEmployeeId);
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Employee Created successfully.`,
                variant: 'success'
            })
        ); 
    }

    createEmployee() {
        this.addEmployeePopup = true;
        console.log(this.addEmployeePopup);
        
    }
    closePop() {
        this.addEmployeePopup = false;
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        if(uploadedFiles.length > 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Image uploaded successfully.`,
                    variant: 'success'
                })
            );
            const documentId = uploadedFiles[0].documentId;
            console.log('id1:', documentId);
            getContentVersionId( {contentDocumentId: documentId} )
                .then(result => {
                    this.contentId = result;
                    console.log('id2:', this.contentId);
                    this.imageUrl = '/sfc/servlet.shepherd/version/download/' + this.contentId;
                    console.log(this.imageUrl);
                })
            const recordId = this.newEmployeeId; 
            console.log('r', recordId);
            console.log(this.imageUrl);
            const fields = {
                Id: recordId,
                Image__c: `<img src="${this.imageUrl}" alt="Employee Image"/>`
            };
            console.log('fields:', fields);
            const recordInput = { fields };

            updateRecord(recordInput)
                .then(() => {
                    console.log('record updated');
                })
                .catch((error) => {
                    console.error('error: ', error);
                });
            
        }
    }

    handleRowAction(event) {
        const row = event.detail.row;
        this.selectedEmployeeId = row.Id;
        this.showEmployeeDetails = true;
        console.log('selectedEmployeeId:', this.selectedEmployeeId);
        // console.log(this.employees);
        // console.log(this.employees.find(employee => employee.Id === this.selectedEmployeeId));
        const empImage = this.employees.find(employee => employee.Id === this.selectedEmployeeId);
        this.employeeImageField = empImage.Image__c;
    }
    
    handleSuccessor(event) {
        this.showEmployeeDetails = false;
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: `Employee Details Updated Successfully.`,
                variant: 'success'
            })
        );
    }

    closeModal(){
        this.showEmployeeDetails = false;
        this.employeeTransfer = false;
    }
    handleBranchChange(event){
        this.targetBranchId = event.detail.value;
        console.log(this.targetBranchId);
    }

    transferEmployee(){
        this.employeeTransfer = true;
        console.log('record Id :',this.recordId);
    }

    handleTransferEmployee(){
        transferEmployee({
            employeeId : this.selectedEmployeeId,
            newBranchId: this.targetBranchId
        })
        .then(result => {
            deleteEmployee( {employeeId : this.selectedEmployeeId} );
            this.employeeTransfer = false;
            this.showEmployeeDetails = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Employee Transferred Successfully.`,
                    variant: 'success'
                })
            );
        })
        .catch(error => {
            console.log(error);
        });
    }

    deletePop(){
        this.deletePopup = true;
    }

    closeDelete(){
        this.deletePopup = false;
    }
    
    handleDeleteEmployee(){
        deleteEmployee({employeeId : this.selectedEmployeeId})
        .then(result => {   
            this.showEmployeeDetails = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: `Employee Deleted Successfully.`,
                    variant: 'success'
                })
            );
            this.deletePopup = false;
            return refreshApex(this.constBId);
        })
        .catch(error => {
            console.log(error);
        });
    }
}