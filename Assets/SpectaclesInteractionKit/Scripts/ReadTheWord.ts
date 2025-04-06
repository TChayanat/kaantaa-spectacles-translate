@component
export class ReadTheWord extends BaseScriptComponent {
  private jsonString: string = `
    {
      "name": "女性",
      "romanization": "Josei",
      "phonetic": "/d͡ʑo̞se̞ː/",
      "eng": "Woman",
      "etymology": "From Sino-Japanese 女性 (josei), from 女 (jo, 'woman') + 性 (sei, 'sex, gender')."
    }
  `;

  onAwake(): void {
    print("awake event triggered");

    this.createEvent("OnStartEvent").bind(() => {
      this.onStart();
      print("Onstart event triggered");
    });
  }

  onStart(): void {
    print("lala");

    const data = JSON.parse(this.jsonString);

    // Extract the name and romanization
    const name = data.name;
    const romanization = data.romanization;

    // Format the text
    const formattedText = `${name} (${romanization})`;

    print(formattedText);

    // Get the Text component from the same object
    const textComponent = this.getSceneObject().getComponent("Component.Text");

    if (textComponent) {
      // Set the text of the Text component
      textComponent.text = formattedText;
      print("Text updated on the same object");
    } else {
      print("This object does not have a Text component!");
    }
  }
}