package comp3011.assignment1.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
@Component 
@ConfigurationProperties(prefix = "openai.api")
public class OpenAiProperties {
    private String key;
    private String url;
    private String model;

    public OpenAiProperties() {
        this.url = "https://api.openai.com/v1/audio/transcriptions";
        this.model = "gpt-4o-mini-transcribe";
    }

    public String getKey() { return key; }
    public String getModel() { return model; }
    public String getUrl() { return url; }
    public void setKey(String key) { this.key = key; }
    public void setModel(String model) { this.model = model; }
    public void setUrl(String url) { this.url = url; }

}