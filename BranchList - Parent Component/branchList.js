import { LightningElement, api, wire, track} from 'lwc';
import getBranches from '@salesforce/apex/BranchController.getBranches';


export default class BranchList extends LightningElement {
    @api recordId;
    @track branches = [];
    @track error;
    @track branchPopup = false;
    @track branchId = '';
    @track selectedBranch = {};
    @track pop = false;
   

    @wire(getBranches, {Id : '$recordId'}) wiredBranches({error, data}) {
        if(data) {
            this.branches = data;
            this.error = undefined;
            //console.log(JSON.stringify(this.branches));
        }
        else if(error) {
            this.error = error;
            branches = [];
        }
    }
    
    handleBranchClick(event) {
        this.branchId = event.target.dataset.id;
        this.selectedBranch = this.branches.find(branch => branch.Id === this.branchId);
        this.branchPopup = true;
        console.log('branchid=', this.branchId);

    }

    closeBranchPopup() {
        this.branchPopup = false;
        this.selectedBranch = {};
    }

    handleEmployeeDetails() {
        this.pop = true;
        this.branchPopup = false;
    }
    employeeClose(event) {
        this.pop = false;
    }

}

