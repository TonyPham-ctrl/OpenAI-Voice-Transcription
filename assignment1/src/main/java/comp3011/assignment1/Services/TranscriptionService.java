package comp3011.assignment1.Services;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service 
public class TranscriptionService {
    public String transcribe(MultipartFile audioFile) {
        return "Transcribed text from " + audioFile.getOriginalFilename();
    }
}