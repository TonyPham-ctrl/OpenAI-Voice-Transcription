package comp3011.assignment1.Controllers;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.RequestMapping;

import comp3011.assignment1.Models.TranscriptionResponse;
import comp3011.assignment1.Services.TranscriptionService;


@RestController 
@RequestMapping("/api/v1")
public class TranscriptionController {
    private final TranscriptionService transcriptionService;

    public TranscriptionController(TranscriptionService transcriptionService) {
        this.transcriptionService = transcriptionService;
    }

    @PostMapping ("/transcribe")
    public TranscriptionResponse transcribe(@RequestParam("file") MultipartFile file) {
        System.out.println("Handling on: " + Thread.currentThread());
        String text = transcriptionService.transcribe(file);
        return new TranscriptionResponse(text);
    }
}
