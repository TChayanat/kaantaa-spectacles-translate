@component
export class Gamification extends BaseScriptComponent {

    @input
    recallText : Text

    nouns : Array<string> = []
    currentNoun : string = "";
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
    addNoun(noun: string) {
        this.nouns.push(noun);
    }
    findNoun() {
        if (this.nouns.length == 0) {
            this.recallText.text = "Nothing to recall."
        } else {
            this.currentNoun = this.nouns.pop();
            this.recallText.text = "Find " + this.currentNoun
        }
    }
    scoreAnswer(yesno: string) {
        if (yesno == "yes") {
            this.onCorrect();
        }
        else {
            this.onIncorrect();
        }
    }
    onStart() {
        
    }
    onUpdate() {

    }
    onCorrect() {

    }
    onIncorrect() {

    }
}
