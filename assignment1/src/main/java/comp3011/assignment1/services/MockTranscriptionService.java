package comp3011.assignment1.services;

import org.springframework.stereotype.Service;
import org.springframework.context.annotation.Profile;
import org.springframework.web.multipart.MultipartFile;

@Service
@Profile("local")
public class MockTranscriptionService implements TranscriptionService {
    @Override
    public String transcribe(MultipartFile file) {
        return "This is a mock transcription for local testing.";
    }
}