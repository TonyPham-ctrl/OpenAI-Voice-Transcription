package comp3011.assignment1.services;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

// Used to locally test the API response by mocking / assuming that whoever calls MockTranscriptionService.transcribe would've successfully called OpenAI API and receives a response
@Service
public class MockTranscriptionService implements TranscriptionService {
    @Override
    public String transcribe(MultipartFile file) {
        return "This is a mock transcription for local testing.";
    }
}