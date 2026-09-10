package comp3011.assignment1.Controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import comp3011.assignment1.Models.UptimeResponse;
import comp3011.assignment1.ServerStartTracker;
import comp3011.assignment1.Models.ServerState
;
import java.time.Instant;
import java.time.Duration;

// /api/v1/admin/uptime
// /api/v1/admin/shutdown
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    private final ServerState serverState;

    public AdminController(ServerStartTracker serverStartTracker, ServerState serverState) {
        this.serverState = serverState;
    }

    @PostMapping("/shutdown")
    public String shutdown() {
        serverState.shutdown();
        return "Server shutting down...";
        
    }

    @GetMapping("/uptime")
    public UptimeResponse uptime() {
        Instant start = serverState.getUtcServerStart();
        Instant now = Instant.now();
        double seconds = Duration.between(start, now).toNanos() / 1_000_000_000.0;

        return new UptimeResponse(
            start.toString(),
            now.toString(),
            seconds
        );
    }

    @GetMapping("/running")
        public boolean isRunning() {
            return serverState.isRunning();
        }
}

