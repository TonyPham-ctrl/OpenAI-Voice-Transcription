package comp3011.assignment1.services;

import comp3011.assignment1.config.OpenAiProperties;
import comp3011.assignment1.models.OpenAiTranscriptionResponse;

import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

@Component
public class OpenAiClient {
    private final OpenAiProperties properties;
    private final RestClient restClient;

    public OpenAiClient(OpenAiProperties properties, RestClient.Builder builder) {
        this.properties = properties;
        this.restClient = builder
                .defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + properties.getKey())
                .build();
    }

    public OpenAiTranscriptionResponse handleRequest(MultipartFile audioFile) {
        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        // getResource() keeps the original filename; OpenAI uses its extension to detect the format
        body.add("file", audioFile.getResource());
        body.add("model", properties.getModel());

        return restClient.post()
                .uri(properties.getUrl())
                .contentType(MediaType.MULTIPART_FORM_DATA)
                .body(body)
                .retrieve()
                .body(OpenAiTranscriptionResponse.class);
    }
}
