import { Interactable } from "./SpectaclesInteractionKit/Components/Interaction/Interactable/Interactable";
import { ContainerFrame } from "./SpectaclesInteractionKit/Components/UI/ContainerFrame/ContainerFrame";
import { InteractorEvent } from "./SpectaclesInteractionKit/Core/Interactor/InteractorEvent";

export namespace GameSettings {
    export let isRecall = false
    export let currentNoun = ""
    export let gameControls: GameControls
}

@component
export class GameControls extends BaseScriptComponent {
    static _noMaxwellScene;
    static _yesMaxwellScene;
    static scoreAnswer(arg0: string) {
        if (GameSettings.currentNoun != "") {
            if (arg0 == "yes") {
                this.runYay();
            }
            else {
                this.runNaur();
            }
        }
    }
    static async runYay() {
        GameControls._yesMaxwellScene.enabled = true
        await new Promise(resolve => globalThis.setTimeout(resolve, 1000)); // 1 second
        GameControls._yesMaxwellScene.enabled = false
        GameSettings.gameControls.findNoun();
    }
    static async runNaur() {
        GameControls._noMaxwellScene.enabled = true
        await new Promise(resolve => globalThis.setTimeout(resolve, 1000)); // 1 second
        GameControls._noMaxwellScene.enabled = false
        GameSettings.gameControls.findNoun();
    }

    @input
    yesMaxwellScene : SceneObject
    @input
    noMaxwellScene : SceneObject

    @input
    recallText : Text

    @input
    recallButton : Interactable

    @input
    recallButtonText : Text

    @input
    recallFrame : ContainerFrame

    nouns : Array<string> = []
    onAwake() {
        GameSettings.gameControls = this;
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
            GameSettings.currentNoun = "";
            this.recallText.text = "Nothing to recall."
        } else {
            GameSettings.currentNoun = this.nouns.pop();
            this.recallText.text = "Find " + GameSettings.currentNoun;
        }
    }
    onStart() {
        let onSelectTriggerStart = (event: InteractorEvent) => {
            if (GameSettings.isRecall == false) {
                GameSettings.isRecall = true;
                this.recallButtonText.text = "Goto Freeroam";
                this.recallText.enabled = true;
                this.recallFrame.enabled = true;
                this.findNoun();
            }
            else {
                GameSettings.isRecall = false;
                this.recallButtonText.text = "Goto Recall";
                this.recallText.enabled = false;
                this.recallFrame.enabled = false;
            }
        };
        this.recallButton.onInteractorTriggerStart(onSelectTriggerStart)
        this.recallButton.getSceneObject().enabled = false;
        this.recallFrame.enabled = false;
    }
    onUpdate() {

    }
}