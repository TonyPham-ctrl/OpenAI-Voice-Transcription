package comp3011.assignment1.services;

import org.springframework.boot.SpringApplication;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Service;
import comp3011.assignment1.models.ServerState;

@Service
public class ShutdownService {
    private final ServerState serverState;
    private final ApplicationContext context;

    public ShutdownService(ServerState serverState, ApplicationContext context) {
        this.serverState = serverState;
        this.context = context;
    }

    public boolean requestShutdown() {
        if (!serverState.beginShutdown()) {
            return false;
        }

        Thread.ofPlatform()
            .name("app-shutdown")
            .daemon(false)
            .start(() -> System.exit(SpringApplication.exit(context)));
        return true;
    }
}
