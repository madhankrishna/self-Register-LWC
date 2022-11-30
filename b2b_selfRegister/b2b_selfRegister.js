import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import selfRegister from '@salesforce/apex/B2B_SelfRegisterController.registerUser';


export default class B2b_selfRegister extends LightningElement {
    isModalOpen = false;
    fName;
    lName;
    username;
    company;
    email;
    phone;
    password;
    errorMsg;
    showError = false
    confrimPassword;
    isPasswordMatched = false;
    missMatchPasswordErrorMsg;
    showSpinner = false;
   


    
    openModal() {
        // to open modal set isModalOpen tarck value as true
        this.isModalOpen = true;
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.isModalOpen = false;
    }

//This method is used to validate all the fields to make sure that all the values entered are correct or not if not show the error msg at the fields
    submitDetails(){
        console.log('init');
        const isInputsCorrectInput = [...this.template.querySelectorAll('lightning-input')]
        .reduce((validSoFar, inputField) => {
            inputField.reportValidity();
            return validSoFar && inputField.checkValidity();
        }, true);

        if(isInputsCorrectInput){
            console.log('if called')
            this.fName = this.template.querySelector("[data-field='FirstName']").value;
            this.lName = this.template.querySelector("[data-field='LastName']").value;
            this.company = this.template.querySelector("[data-field='Company']").value;
            this.email = this.template.querySelector("[data-field='Email']").value;
            this.phone = this.template.querySelector("[data-field='Phone']").value;
            this.password = this.template.querySelector("[data-field='Password']").value;
            this.confrimPassword  = this.template.querySelector("[data-field='Confrim_Password']").value;
            this.username = this.fName+this.lName;
            console.log(this.fName,this.lName,this.company,this.email,this.phone,this.password,this.confrimPassword,this.username);

            if(this.password == this.confrimPassword){
                this.isPasswordMatched = false; 
               
                this.handleRegister(this.fName,this.lName,this.username,this.email,this.fName,this.password,this.company,this.phone);  
                
            }
            else{
                console.log('password mismatced')
                this.isPasswordMatched = true;
                this.missMatchPasswordErrorMsg = 'Your Password was Mismatched please check'
            }
            
        }  

        
    }

    handleRegister(fname,lname,uname,userEmail,nickname,pascode,accname,pNumber){
        this.showSpinner = true;
        selfRegister({ firstName: fname, lastName: lname ,username: uname, email: userEmail, communityNickname: nickname, password: pascode,
            AccountName: accname, PhoneNumber : pNumber})
        .then((result)=>{
            
            console.log('register called')
            console.log(result);
            if(result.isEmailExist){
                this.showError = true;
                this.errorMsg = 'Given email was occupied. please check your email';
                this.showSpinner = false;
                
            }
            else if(result.isPhoneNumberExits){
                this.showError = true;
                this.errorMsg = 'Given Phone was there in salesforce';
                this.showSpinner = false;
            }
            else if(result.url){
                let baseURL = result.url;
                console.log(result.url);
                
                window.location.assign(baseURL);
                
                this.showSpinner =false;

            }
        })
        .catch(e => {
            console.log(e);
            this.showError = true;
            this.errorMsg = e;
            this.showSpinner = false;
            const evt = new ShowToastEvent({
                title: 'Error',
                message: e,
                variant: "error",
                mode: "dismissable"
            });
            this.dispatchEvent(evt);
        });
        
    }

}