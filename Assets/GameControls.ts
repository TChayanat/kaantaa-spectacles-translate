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
        this.timestamp = Date.now()
        this.awaitingMaxwell = true;
    }
    static async runNaur() {
        GameControls._noMaxwellScene.enabled = true
        this.timestamp = Date.now()
        this.awaitingMaxwell = true;
    }
    static finishMaxwell() {
        GameControls._yesMaxwellScene.enabled = false;
        GameControls._noMaxwellScene.enabled = false;
        GameSettings.gameControls.findNoun();
    }
    static awaitingMaxwell = false;
    static timestamp;


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
                this.findNoun();
            }
            else {
                GameSettings.isRecall = false;
                this.recallButtonText.text = "Goto Recall";
                this.recallText.enabled = false;
            }
        };
        this.recallButton.onInteractorTriggerStart(onSelectTriggerStart)
        this.recallButton.getSceneObject().enabled = false;
    }
    onUpdate() {
        if (GameControls.awaitingMaxwell == true) {
            let nowDate = Date.now();
            if (nowDate - GameControls.timestamp > 1000) {
                GameControls.awaitingMaxwell = false;
                GameControls.finishMaxwell();
            }
        }
    }
}