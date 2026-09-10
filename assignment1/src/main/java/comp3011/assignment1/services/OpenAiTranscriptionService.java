package comp3011.assignment1.services;

import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import comp3011.assignment1.models.ServerState;
import comp3011.assignment1.models.OpenAiTranscriptionResponse;
@Service
@Primary
public class OpenAiTranscriptionService implements TranscriptionService {
    private final ServerState serverState;
    private final OpenAiClient openAiClient;

    public OpenAiTranscriptionService(OpenAiClient openAiClient, ServerState serverState) {
        this.openAiClient = openAiClient;
        this.serverState = serverState;
    }

    @Override
    public String transcribe(MultipartFile audioFile) {
        OpenAiTranscriptionResponse response = openAiClient.handleRequest(audioFile);
        updateTokenUsage(response);
        return response.getText();
    }

    public void updateTokenUsage(OpenAiTranscriptionResponse response) {
        if (response != null && response.getUsage() != null) {
            serverState.incrementInputTokens(response.getUsage().input_tokens());
            serverState.incrementOutputTokens(response.getUsage().output_tokens());
        }
    }

    
}