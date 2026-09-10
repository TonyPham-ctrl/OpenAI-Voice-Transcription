package comp3011.assignment1.services;

import comp3011.assignment1.config.OpenAiProperties;
import comp3011.assignment1.models.OpenAiTranscriptionResponse;
import org.springframework.stereotype.Component;

import org.springframework.web.multipart.MultipartFile;

@Component 
public class OpenAiClient {
    private final OpenAiProperties properties;

    public OpenAiClient(OpenAiProperties properties) {
        this.properties = properties;
    }
    public OpenAiTranscriptionResponse sendRequest(MultipartFile audioFile) {
        return new OpenAiTranscriptionResponse("test", new OpenAiTranscriptionResponse.Usage(0, 0, 0));
    }

}
