package comp3011.assignment1.services;

import org.springframework.stereotype.Service;
import org.springframework.context.annotation.Profile;
import org.springframework.web.multipart.MultipartFile;

@Service
@Profile("titan")
public class OpenAiTranscriptionService implements TranscriptionService {
    @Override
    public String transcribe(MultipartFile audioFile) {
        
        return "real transcription";
    }
}