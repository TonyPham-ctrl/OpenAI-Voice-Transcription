package comp3011.assignment1.Controllers;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.GetMapping;

import comp3011.assignment1.Models.UptimeResponse;

// /api/v1/admin/uptime
// /api/v1/admin/shutdown
@RestController
@RequestMapping("/api/v1/admin")
public class AdminController {
    

    @GetMapping("/shutdown")
    public String shutdown() {
        return "Server shutting down...";
    }

    @GetMapping ("/uptime")
    public UptimeResponse uptime() {
        return new UptimeResponse(
        "2026-07-14T01:15:30Z",
        "2026-07-14T03:45:30.500Z",
        9000.5
    );
    }
}
