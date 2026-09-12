package comp3011.assignment1.controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import comp3011.assignment1.models.ServerState;
import comp3011.assignment1.models.UptimeResponse;
import comp3011.assignment1.models.ErrorResponse;
import comp3011.assignment1.models.ShutdownResponse;
import comp3011.assignment1.services.ShutdownService;
import java.time.Instant;
import java.time.Duration;

// /api/v1/admin/uptime
// /api/v1/admin/shutdown
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {

    private final ServerState serverState;
    private final ShutdownService shutdownService;

    public AdminController(ServerState serverState, ShutdownService shutdownService) {
        this.serverState = serverState;
        this.shutdownService = shutdownService;
    }

    @PostMapping("/shutdown")
    public ResponseEntity<?> shutdown() {
        if (!shutdownService.requestShutdown()) {
            ErrorResponse err = new ErrorResponse(
                Instant.now().toString(), 409, "Conflict",
                "Graceful shutdown is already in progress.",
                "/api/v1/admin/shutdown");
            return ResponseEntity.status(409).body(err);
        }
        return ResponseEntity.status(202).body(new ShutdownResponse("Graceful shutdown requested."));
    }

    @GetMapping("/uptime")
    public UptimeResponse uptime() {
        System.out.println("Handling on: " + Thread.currentThread());

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

