{ lib, llm }:
if (lib.strings.versionOlder lib.version "25.10") then
  llm
else
  (llm.override {
    enable-llm-anthropic = true;
    enable-llm-cmd = true;
    enable-llm-fragments-github = true;
    enable-llm-gemini = true;
    enable-llm-gguf = true;
    enable-llm-jq = true;
    enable-llm-ollama = true;
    enable-llm-openai-plugin = true;
  }).overrideAttrs
    {
      passthru.tests = { };
    }
