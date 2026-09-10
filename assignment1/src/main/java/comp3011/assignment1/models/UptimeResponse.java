package comp3011.assignment1.models;

public record UptimeResponse(
    String utcServerStart,
    String utcNow,
    double serverUptimeSeconds
) {}