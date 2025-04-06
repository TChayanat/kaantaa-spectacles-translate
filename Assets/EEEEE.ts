@component
export class EEEEE extends BaseScriptComponent {
    @input
    audio: AudioComponent;
    
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
        this.onDialogueStart();
    }
    onUpdate() {

    }
    onDialogueStart() {
        this.audio.play(-1);
    }
    onDialogueStop() {
        this.audio.stop(false);
    }
}
