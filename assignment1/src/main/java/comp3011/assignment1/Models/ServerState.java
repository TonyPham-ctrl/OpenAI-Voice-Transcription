package comp3011.assignment1.Models;

import org.springframework.stereotype.Component;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicLong;
import jakarta.annotation.PostConstruct;


@Component
public class ServerState {
    private Instant utcServerStart;
    private final AtomicLong inputTokens = new AtomicLong();
    private final AtomicLong outputTokens = new AtomicLong();
    private final AtomicBoolean isRunning = new AtomicBoolean(true);
    private final AtomicBoolean shuttingDown = new AtomicBoolean(false);

    @PostConstruct
    public void init() {
        this.utcServerStart = Instant.now();
        this.isRunning.set(true);
        this.shuttingDown.set(false);
    }

    public Instant getUtcServerStart() {
        return utcServerStart;
    }

    public boolean isRunning() {
        return isRunning.get();
    }

    public boolean isShuttingDown() {
        return shuttingDown.get();
    }

    public void shutdown() {
        shuttingDown.set(true);
    }

}