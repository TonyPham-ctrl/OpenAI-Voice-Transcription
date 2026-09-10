package comp3011.assignment1.models;

import org.springframework.stereotype.Component;
import java.time.Instant;
import java.util.concurrent.atomic.AtomicBoolean;
import jakarta.annotation.PostConstruct;


@Component
public class ServerState {
    private Instant utcServerStart;
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