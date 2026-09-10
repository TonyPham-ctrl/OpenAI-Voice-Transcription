package comp3011.assignment1.models;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OpenAiTranscriptionResponse(
    String text,
    Usage usage
) {
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Usage(
        long input_tokens,
        long output_tokens,
        long total_tokens
    ) {}

    public String getText() {
        return text;
    }

    public Usage getUsage() {
        return usage;
    }
}