export namespace GameSettings {
    export let isRecall = false
    export let currentNoun = ""
}

@component
export class GameControls extends BaseScriptComponent {
    static _noMaxwellScene;
    static _yesMaxwellScene;
    static scoreAnswer(arg0: string) {
        if (arg0 == "yes") {
            this.runYay();
        }
        else {
            this.runNaur();
        }
    }
    static async runYay() {
        GameControls._yesMaxwellScene.enabled = true
        await new Promise(resolve => globalThis.setTimeout(resolve, 1000)); // 1 second
        GameControls._yesMaxwellScene.enabled = false
    }
    static async runNaur() {
        GameControls._noMaxwellScene.enabled = true
        await new Promise(resolve => globalThis.setTimeout(resolve, 1000)); // 1 second
        GameControls._noMaxwellScene.enabled = false
    }

    @input
    yesMaxwellScene : SceneObject
    @input
    noMaxwellScene : SceneObject

    @input
    recallText : Text

    nouns : Array<string> = []
    onAwake() {
        GameControls._yesMaxwellScene = this.yesMaxwellScene;
        GameControls._noMaxwellScene = this.noMaxwellScene;
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
            GameSettings.currentNoun = this.nouns.pop();
            this.recallText.text = "Find " + GameSettings.currentNoun;
        }
    }
    onStart() {
        
    }
    onUpdate() {

    }
}