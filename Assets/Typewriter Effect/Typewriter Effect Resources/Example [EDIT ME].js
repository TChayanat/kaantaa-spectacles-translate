// This is an example of using TypewriterEffect from another script 
//@input string[] textInput 
var idx = 0;

global.typeText(script.textInput[idx], true);

script.createEvent("TapEvent").bind(function(eventData){
    idx += 1;
    if(idx < script.textInput.length) {
        global.typeText(script.textInput[idx], true);
    }
});


// Trigger from the behavior script instead: 
// Add New -> Helper Hcripts -? Behavior in resources panel
// add Behavior script to scene and configure:

// Trigger - any 
// Response - Call Object Api
// Target Type - Global Api
// Call Type - Call Function 
// Function Name - 'typeText'
// Argument 1 : 
//      Value Type - string 
//      String Value - enter text to type 
// Argument 2 : 
//      Value Type - bool 
//      Bool Value - true/false (repeat or not)