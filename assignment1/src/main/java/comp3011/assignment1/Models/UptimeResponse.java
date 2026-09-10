package comp3011.assignment1.Models;

public record UptimeResponse(
    String utcServerStart,
    String utcNow,
    double serverUptimeSeconds
) {}