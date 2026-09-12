package comp3011.assignment1.services;

import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;
import comp3011.assignment1.models.ServerState;

// Service dedicated to shutting down the server gracefully
@Service
public class ShutdownService {
    private final ServerState serverState;
    private final ApplicationContext context;

    public ShutdownService(ServerState serverState, ApplicationContext context) {
        this.serverState = serverState;
        this.context = context;
    }

    public boolean requestShutdown() {
        // thread-safe method to check if shutdown has already began and marks as shutdown in atomic step 
        if (!serverState.beginShutdown()) {
            return false;
        }
        
        // spawn a platform thread to concurrently handles shutdown so that the thread is non-blocking while waiting for app to shutdown
        Thread.ofPlatform()
            .name("app-shutdown")

            // platform thread instead of virtual - keep jvm alive until this thread complete
            .daemon(false)
            .start(() -> System.exit(SpringApplication.exit(context)));
        return true;
    }
}
