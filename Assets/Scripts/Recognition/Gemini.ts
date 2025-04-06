import { LanguageSettings } from "../../LanguageControls";

@component
export class Gemini extends BaseScriptComponent {
    @input remoteServiceModule: RemoteServiceModule;

    private ImageQuality = CompressionQuality.HighQuality;
    private ImageEncoding = EncodingType.Jpg;

    private key = "INSERT GEMINI KEY HERE";

    onAwake() {}

    makeImageRequest(imageTex: Texture, callback) {
        print("Making image request...");
        Base64.encodeTextureAsync(
            imageTex,
            (base64String) => {
                print("Image encode Success!");
                const textQuery = `Identify the main subject of the image using this JSON schema:
                {
                    "name": String describe using one noun in ${LanguageSettings.globalLanguageVariable} language,
                    "romanization": Romanized pronunciation of the object's name,
                    "phonetic": Pronunciation of the object's name in Modern IPA,
                    "eng": String describe using one noun in English,
                    "etymology": etymology in English of the name in ${LanguageSettings.globalLanguageVariable} where foreign words ares 
                    structured as word (pronunciation) no longer than 13 words,
                }`;
                this.sendGemini(textQuery, base64String, callback);
            },
            () => {
                print("Image encoding failed!");
            },
            this.ImageQuality,
            this.ImageEncoding
        );
    }

    makeImageCheck(word: String, imageTex: Texture, callback) {
        print("Making image request...");
        Base64.encodeTextureAsync(
            imageTex,
            (base64String) => {
                print("Image encode Success!");
                const textQuery = `return a single boolean value whether the provided image is similar
                enough to the word, ${word}`;
                this.checkGemini(textQuery, base64String, callback);
            },
            () => {
                print("Image encoding failed!");
            },
            this.ImageQuality,
            this.ImageEncoding
        );
    }

    async sendGemini(
        request: string,
        image64: string,
        callback: (response: string) => void
    ) {
        const reqObj = {
            contents: [
                {
                    parts: [
                        { text: request },
                        {
                            inline_data: {
                                mime_type: "image/jpeg", // Adjust if your image type is different
                                data: image64,
                            },
                        },
                    ],
                },
            ],
        };

        const webRequest = new Request(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.key}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(reqObj),

            }
        );

        let resp = await this.remoteServiceModule.fetch(webRequest);
        if (resp.status == 200) {
            let bodyText = await resp.text();
            print("GOT: " + bodyText);
            var bodyJson = JSON.parse(bodyText);

            if (bodyJson.candidates[0].content.parts[0].text && bodyJson.candidates[0].content.parts[0].text.length > 0) {
                bodyJson.mainText = bodyJson.candidates[0].content.parts[0].text.slice(8, -3);
                var mainJson = JSON.parse(bodyJson.mainText);
                callback(`${mainJson.name}\n${mainJson.romanization}\n${mainJson.eng}\n${mainJson.etymology}`);
                print(bodyJson.mainText);
            }
        } else {
            print("error code: " + resp.status);
            print("MAKE SURE YOUR API KEY IS SET IN THIS SCRIPT!");
        }
    }

    async checkGemini(
        request: string,
        image64: string,
        callback: (response: string) => void
    ) {
        const reqObj = {
            contents: [
                {
                    parts: [
                        { text: request },
                        {
                            inline_data: {
                                mime_type: "image/jpeg", // Adjust if your image type is different
                                data: image64,
                            },
                        },
                    ],
                },
            ],
        };

        const webRequest = new Request(
            `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${this.key}`,
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(reqObj),

            }
        );

        let resp = await this.remoteServiceModule.fetch(webRequest);
        if (resp.status == 200) {
            let bodyText = await resp.text();
            print("GOT: " + bodyText);
            var bodyJson = JSON.parse(bodyText);

            if (bodyJson.candidates[0].content.parts[0].text && bodyJson.candidates[0].content.parts[0].text.length > 0) {
                bodyJson.mainText = bodyJson.candidates[0].content.parts[0].text;
                var match;
                try {
                    match = JSON.parse(bodyJson.mainText.toLowerCase());
                } catch (e) {
                    match = false;
                }
                callback(match);
                print(match);
            }
        } else {
            print("error code: " + resp.status);
            print("MAKE SURE YOUR API KEY IS SET IN THIS SCRIPT!");
        }
    }
}
