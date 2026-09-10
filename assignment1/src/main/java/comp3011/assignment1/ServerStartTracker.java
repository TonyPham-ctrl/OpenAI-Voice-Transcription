package comp3011.assignment1;

import org.springframework.stereotype.Component;
import java.time.Instant;
import jakarta.annotation.PostConstruct;

@Component 
public class ServerStartTracker {
    private Instant utcServerStart;
    

    @PostConstruct
    public void init(){
        this.utcServerStart = Instant.now();
    }

    public Instant getUtcServerStart() {
        return utcServerStart;
    }
}
