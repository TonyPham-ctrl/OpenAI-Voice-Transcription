package comp3011.assignment1.services;

import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service 
public interface TranscriptionService {
    public String transcribe(MultipartFile audioFile);
}