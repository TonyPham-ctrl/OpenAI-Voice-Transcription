package comp3011.assignment1.controllers;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import comp3011.assignment1.models.GlobalStatsResponse;
import comp3011.assignment1.models.ServerState;

@RestController
@RequestMapping("/api/v1/global")
public class GlobalController {

    private final ServerState serverState;

    public GlobalController(ServerState serverState) {
        this.serverState = serverState;
    }

    @GetMapping("/stats")
    public GlobalStatsResponse getStats() {
        return new GlobalStatsResponse(
            serverState.getInputTokens(),
            serverState.getOutputTokens()
        );
    }
}