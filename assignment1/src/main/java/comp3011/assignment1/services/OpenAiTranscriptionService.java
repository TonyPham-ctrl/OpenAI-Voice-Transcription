package comp3011.assignment1.services;

import org.springframework.stereotype.Service;
import org.springframework.context.annotation.Profile;
import org.springframework.web.multipart.MultipartFile;

import comp3011.assignment1.models.OpenAiTranscriptionResponse;
@Service
@Profile("titan")
public class OpenAiTranscriptionService implements TranscriptionService {

    private final OpenAiClient openAiClient;

    public OpenAiTranscriptionService(OpenAiClient openAiClient) {
        this.openAiClient = openAiClient;
    }

    @Override
    public String transcribe(MultipartFile audioFile) {
        OpenAiTranscriptionResponse response = openAiClient.handleRequest(audioFile);
        return response.getText();
    }
}