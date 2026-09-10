package comp3011.assignment1.Controllers;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// /api/v1/admin/transcribe
// /api/v1/admin/stats

@RestController 
@RequestMapping("/api/v1/global")
public class GlobalController {
    
    public GlobalController() {
    };

    @PostMapping ("/transcribe")
    public String transcribe() {
        Thread.Builder builder = Thread.ofVirtual().name("worker-", 0);
        Runnable task = () -> {
            System.out.println("Thread ID: " + Thread.currentThread().threadId());
        };

        
    }
}
