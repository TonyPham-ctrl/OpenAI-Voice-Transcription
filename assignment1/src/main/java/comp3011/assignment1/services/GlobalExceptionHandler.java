package comp3011.assignment1.services;

import java.time.Instant;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import comp3011.assignment1.models.ErrorResponse;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<ErrorResponse> handleTooLarge(
            MaxUploadSizeExceededException e, HttpServletRequest req) {
        ErrorResponse body = new ErrorResponse(
            Instant.now().toString(),
            413,
            "Payload Too Large",
            "Uploaded audio exceeds the maximum allowed size.",
            req.getRequestURI());
        return ResponseEntity.status(413).body(body);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(
            Exception e, HttpServletRequest req) {
        // Spring's own exceptions (unknown path, wrong HTTP method, ...) carry their real status.
        // Without this they'd be reported as 500 even though the client caused them.
        if (e instanceof org.springframework.web.ErrorResponse springError) {
            int status = springError.getStatusCode().value();
            HttpStatus known = HttpStatus.resolve(status);
            String reason = known != null ? known.getReasonPhrase() : "Error";
            String detail = springError.getBody().getDetail();
            ErrorResponse body = new ErrorResponse(
                Instant.now().toString(),
                status,
                reason,
                detail != null ? detail : reason,
                req.getRequestURI());
            return ResponseEntity.status(status).body(body);
        }

        ErrorResponse body = new ErrorResponse(
            Instant.now().toString(),
            500,
            "Internal Server Error",
            "An unexpected server error occurred.",
            req.getRequestURI());
        return ResponseEntity.status(500).body(body);
    }
}