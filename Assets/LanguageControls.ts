import { Interactable } from "./SpectaclesInteractionKit/Components/Interaction/Interactable/Interactable";
import { InteractorEvent } from "./SpectaclesInteractionKit/Core/Interactor/InteractorEvent";

@component
export class LanguageControls extends BaseScriptComponent {

    @input
    public language : Text;

    @input
    public languagePlaceholder : Text;

    @input
    public selectInteractable : Interactable;

    @input
    public retryInteractable : Interactable;

    onAwake() {
        this.createEvent("OnStartEvent").bind(() => {
            this.onStart();
            //print("Onstart event triggered");
        });
        this.createEvent("UpdateEvent").bind(() => {
            this.onUpdate();
            //print("Update event triggered");
        });

        
    }
    onStart() {
        let onSelectTriggerStart = (event: InteractorEvent) => {
            // !! MOVE ON TO NEXT STEP!
        };

        let onRetryTriggerStart = (event: InteractorEvent) => {
            this.language.text = "";
        };

        this.selectInteractable.onInteractorTriggerStart(onSelectTriggerStart);
        this.retryInteractable.onInteractorTriggerStart(onRetryTriggerStart);
    }
    onUpdate() {
        if (this.language.text == "") {
            //print("No text")
            this.languagePlaceholder.enabled = true
            this.language.enabled = false
        } else {
            //print("Some text")
            this.languagePlaceholder.enabled = false
            this.language.enabled = true
        }
    }
    
    
    
    
}
