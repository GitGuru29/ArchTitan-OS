// TITAN AI — C++ engine for ChatGPT, Claude, Gemini and Google Search.
// Standard library + libcurl + OpenSSL. No credentials are stored in the ISO.
#include <algorithm>
#include <cctype>
#include <cerrno>
#include <chrono>
#include <cmath>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <initializer_list>
#include <iostream>
#include <map>
#include <optional>
#include <poll.h>
#include <set>
#include <sstream>
#include <stdexcept>
#include <string>
#include <sys/socket.h>
#include <sys/stat.h>
#include <netinet/in.h>
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>
#include <vector>

#include <openssl/sha.h>

#include "http.hpp"
#include "json.hpp"

namespace fs = std::filesystem;

constexpr const char *VERSION = "2.0.0";
constexpr const char *GOOGLE_AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
constexpr const char *GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
constexpr const char *GOOGLE_DEVICE_URL = "https://oauth2.googleapis.com/device/code";
constexpr const char *GOOGLE_SCOPES =
    "https://www.googleapis.com/auth/cloud-platform "
    "https://www.googleapis.com/auth/generative-language.retriever";
constexpr const char *DEFAULT_SYSTEM =
    "You are Titan AI, a helpful assistant running in the ArchTitan OS terminal. "
    "Be concise and clear; use Markdown where it helps.";

struct TitanError : std::runtime_error {
    using std::runtime_error::runtime_error;
};

// ── small helpers ────────────────────────────────────────────────────────────

static bool colour() {
    return isatty(1) && std::getenv("NO_COLOR") == nullptr;
}
static std::string paint(const std::string &code, const std::string &text) {
    return colour() ? "\033[" + code + "m" + text + "\033[0m" : text;
}
static std::string dim(const std::string &s) { return paint("2", s); }
static std::string cyan(const std::string &s) { return paint("36", s); }
static std::string green(const std::string &s) { return paint("32", s); }
static std::string red(const std::string &s) { return paint("31", s); }

static std::string env(const std::string &name, const std::string &fallback = "") {
    const char *v = std::getenv(name.c_str());
    return v && *v ? v : fallback;
}
static std::string first_env(std::initializer_list<const char *> names) {
    for (const char *name : names) {
        std::string v = env(name);
        if (!v.empty()) return v;
    }
    return "";
}
static std::string lower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return s;
}
static bool starts_with(const std::string &s, const std::string &prefix) {
    return s.rfind(prefix, 0) == 0;
}
static std::string trim(std::string s) {
    auto not_space = [](unsigned char c) { return !std::isspace(c); };
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), not_space));
    s.erase(std::find_if(s.rbegin(), s.rend(), not_space).base(), s.end());
    return s;
}
static std::string mask(const std::string &value) {
    if (value.empty()) return dim("(not set)");
    if (value.size() <= 8) return "****";
    return value.substr(0, 4) + "..." + value.substr(value.size() - 4);
}

static const tj::Value *dig(const tj::Value &root, std::initializer_list<std::string> keys) {
    const tj::Value *node = &root;
    for (const std::string &key : keys) {
        if (!node || !node->is_object()) return nullptr;
        node = node->find(key);
    }
    return node;
}
static std::string cfg_string(const tj::Value &cfg, std::initializer_list<std::string> keys,
                              const std::string &from_env, const std::string &fallback = "") {
    std::string e = from_env.empty() ? "" : env(from_env);
    if (!e.empty()) return e;
    const tj::Value *v = dig(cfg, keys);
    if (v && v->is_string() && !v->str.empty()) return v->str;
    return fallback;
}

// ── config / private files ───────────────────────────────────────────────────

static fs::path config_dir() {
    std::string base = env("XDG_CONFIG_HOME");
    if (base.empty()) base = env("HOME", "/root") + "/.config";
    return fs::path(base) / "archtitan";
}
static fs::path config_path() { return config_dir() / "titan-ai.json"; }
static fs::path oauth_path() { return config_dir() / "titan-ai-google.json"; }
static fs::path adc_path() { return fs::path(env("HOME", "/root")) / ".config/gcloud/application_default_credentials.json"; }

static void write_private(const fs::path &path, const tj::Value &data) {
    std::error_code ec;
    fs::create_directories(path.parent_path(), ec);
    chmod(path.parent_path().c_str(), 0700);
    int fd = open(path.c_str(), O_WRONLY | O_CREAT | O_TRUNC, 0600);
    if (fd < 0) throw TitanError("cannot write " + path.string() + ": " + std::strerror(errno));
    std::string text = data.dump(2) + "\n";
    ssize_t written = write(fd, text.data(), text.size());
    fchmod(fd, 0600);
    close(fd);
    if (written != static_cast<ssize_t>(text.size()))
        throw TitanError("short write to " + path.string());
}

static tj::Value read_json_file(const fs::path &path, bool required = false) {
    std::ifstream in(path);
    if (!in) {
        if (required) throw TitanError("cannot read " + path.string());
        return tj::Value::null();
    }
    std::stringstream buffer;
    buffer << in.rdbuf();
    try {
        return tj::Value::parse(buffer.str());
    } catch (const std::runtime_error &e) {
        if (required) throw TitanError("invalid JSON in " + path.string() + ": " + e.what());
        return tj::Value::null();
    }
}
static tj::Value load_config() {
    if (!fs::exists(config_path())) return tj::Value::object();
    tj::Value cfg = read_json_file(config_path(), true);
    if (!cfg.is_object()) throw TitanError("config must be a JSON object: " + config_path().string());
    return cfg;
}
static void save_config(const tj::Value &cfg) { write_private(config_path(), cfg); }

// ── provider / auth metadata ─────────────────────────────────────────────────

static const std::vector<std::string> PROVIDERS = {"openai", "claude", "gemini"};
static std::string label(const std::string &p) {
    if (p == "openai") return "ChatGPT (OpenAI)";
    if (p == "claude") return "Claude (Anthropic)";
    return "Gemini (Google)";
}
static std::optional<std::string> normalise_provider(const std::string &raw) {
    std::string name = lower(trim(raw));
    if (name.empty() || name == "auto") return std::nullopt;
    if (name == "chatgpt") return "openai";
    if (name == "anthropic") return "claude";
    if (name == "openai" || name == "claude" || name == "gemini" || name == "google")
        return name == "google" ? "gemini" : name;
    throw TitanError("unknown provider '" + raw + "' (openai/chatgpt, claude/anthropic, gemini/google, auto)");
}
static std::string default_model(const std::string &p) {
    if (p == "openai") return "gpt-5.4-mini";
    if (p == "claude") return "claude-haiku-5-5";
    return "gemini-2.5-flash";
}
static std::string default_base(const std::string &p) {
    if (p == "openai") return "https://api.openai.com/v1";
    if (p == "claude") return "https://api.anthropic.com";
    return "https://generativelanguage.googleapis.com";
}
static std::string api_key(const tj::Value &cfg, const std::string &p) {
    if (p == "openai") return cfg_string(cfg, {"providers", "openai", "api_key"}, "OPENAI_API_KEY");
    if (p == "claude") return first_env({"ANTHROPIC_API_KEY", "CLAUDE_API_KEY"}).empty()
        ? cfg_string(cfg, {"providers", "claude", "api_key"}, "")
        : first_env({"ANTHROPIC_API_KEY", "CLAUDE_API_KEY"});
    return first_env({"GEMINI_API_KEY", "GOOGLE_API_KEY"}).empty()
        ? cfg_string(cfg, {"providers", "gemini", "api_key"}, "")
        : first_env({"GEMINI_API_KEY", "GOOGLE_API_KEY"});
}
static std::string model_for(const tj::Value &cfg, const std::string &p, const std::string &override) {
    if (!override.empty()) return override;
    std::string env_name = "TITAN_AI_" + lower(p) + "_MODEL";
    if (p == "claude") env_name = "TITAN_AI_CLAUDE_MODEL";
    return cfg_string(cfg, {"models", p}, env_name, default_model(p));
}
static std::string base_for(const tj::Value &cfg, const std::string &p) {
    std::string env_name = p == "openai" ? "OPENAI_BASE_URL"
                           : p == "claude" ? "ANTHROPIC_BASE_URL" : "GEMINI_BASE_URL";
    std::string base = cfg_string(cfg, {"providers", p, "base_url"}, env_name, default_base(p));
    while (!base.empty() && base.back() == '/') base.pop_back();
    return base;
}

struct Cred { std::string method, secret; };

static std::string oauth_access_token(tj::Value &saved);
static std::string google_adc_token();

static Cred google_credentials(tj::Value &cfg) {
    std::string mode = lower(env("TITAN_AI_GOOGLE_AUTH", "auto"));
    std::string key = api_key(cfg, "gemini");
    tj::Value saved = fs::exists(oauth_path()) ? read_json_file(oauth_path()) : tj::Value::null();
    bool has_oauth = saved.is_object();

    if (mode == "api_key") {
        if (key.empty()) throw TitanError("TITAN_AI_GOOGLE_AUTH=api_key but no Gemini API key is set");
        return {"api_key", key};
    }
    if (mode == "oauth") {
        if (!has_oauth) throw TitanError("TITAN_AI_GOOGLE_AUTH=oauth but no sign-in found; run `titan-ai auth google`");
        return {"oauth", oauth_access_token(saved)};
    }
    if (mode == "adc") {
        std::string token = google_adc_token();
        if (token.empty()) throw TitanError("TITAN_AI_GOOGLE_AUTH=adc but no gcloud credentials found");
        return {"adc", token};
    }
    if (mode != "auto") throw TitanError("TITAN_AI_GOOGLE_AUTH must be auto, api_key, oauth or adc");

    if (has_oauth) {
        try {
            return {"oauth", oauth_access_token(saved)};
        } catch (const TitanError &) {
            if (key.empty()) throw;
        }
    }
    if (!key.empty()) return {"api_key", key};
    std::string token = google_adc_token();
    if (!token.empty()) return {"adc", token};
    throw TitanError("Google access not configured. Run `titan-ai setup` for an API key "
                     "or `titan-ai auth google` to sign in.");
}

static bool has_credentials(const tj::Value &cfg, const std::string &p) {
    if (p == "gemini")
        return !api_key(cfg, p).empty() || fs::exists(oauth_path()) || fs::exists(adc_path());
    return !api_key(cfg, p).empty();
}
static std::string resolve_provider(const tj::Value &cfg, const std::string &requested, bool need_key = true) {
    std::string name;
    if (requested.empty()) {
        const tj::Value *def = dig(cfg, {"default_provider"});
        auto auto_name = normalise_provider(def && def->is_string() ? def->str : "auto");
        if (auto_name) name = *auto_name;
    } else {
        auto n = normalise_provider(requested);
        if (n) name = *n;
    }
    if (name.empty()) {
        // Google/Gemini is the default experience: sign-in or an API key wins first.
        if (has_credentials(cfg, "gemini")) return "gemini";
        for (const auto &p : PROVIDERS)
            if (p != "gemini" && has_credentials(cfg, p)) return p;
        throw TitanError("no credentials found. Sign in with Google (`titan-ai auth google`) "
                         "or run `titan-ai setup`.");
    }
    if (need_key && !has_credentials(cfg, name)) {
        std::string hint = name == "gemini" ? "`titan-ai auth google`" : "`titan-ai setup`";
        throw TitanError("no credentials for " + label(name) + ". Run " + hint + ".");
    }
    return name;
}

// ── OAuth helpers ────────────────────────────────────────────────────────────

static std::map<std::string, std::string> parse_query(const std::string &query) {
    std::map<std::string, std::string> out;
    std::stringstream ss(query);
    std::string part;
    auto unescape = [](std::string s) {
        std::string r;
        for (size_t i = 0; i < s.size(); ++i) {
            if (s[i] == '+') r += ' ';
            else if (s[i] == '%' && i + 2 < s.size()) {
                std::string hex = s.substr(i + 1, 2);
                r += static_cast<char>(std::strtol(hex.c_str(), nullptr, 16));
                i += 2;
            } else r += s[i];
        }
        return r;
    };
    while (std::getline(ss, part, '&')) {
        size_t eq = part.find('=');
        if (eq == std::string::npos) continue;
        out[unescape(part.substr(0, eq))] = unescape(part.substr(eq + 1));
    }
    return out;
}

static void random_bytes(unsigned char *out, size_t len) {
    FILE *f = std::fopen("/dev/urandom", "rb");
    if (!f || std::fread(out, 1, len, f) != len) {
        if (f) std::fclose(f);
        throw TitanError("cannot read /dev/urandom for OAuth state");
    }
    std::fclose(f);
}

static std::string b64url(const unsigned char *data, size_t len) {
    static const char *table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
    std::string out;
    for (size_t i = 0; i < len; i += 3) {
        unsigned v = data[i] << 16;
        if (i + 1 < len) v |= data[i + 1] << 8;
        if (i + 2 < len) v |= data[i + 2];
        out += table[(v >> 18) & 63];
        out += table[(v >> 12) & 63];
        if (i + 1 < len) out += table[(v >> 6) & 63];
        if (i + 2 < len) out += table[v & 63];
    }
    return out;
}

static std::string pkce_challenge(const std::string &verifier) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(reinterpret_cast<const unsigned char *>(verifier.data()), verifier.size(), hash);
    return b64url(hash, sizeof(hash));
}

static void save_token_response(const tj::Value &data, const std::string &client_id,
                                const std::string &secret) {
    tj::Value saved = tj::Value::object();
    saved["client_id"] = tj::Value::string(client_id);
    saved["client_secret"] = tj::Value::string(secret);
    saved["access_token"] = tj::Value::string(data.find("access_token") ? data.find("access_token")->str : "");
    if (const tj::Value *rt = data.find("refresh_token"))
        saved["refresh_token"] = tj::Value::string(rt->str);
    else saved["refresh_token"] = tj::Value::null();
    saved["scope"] = tj::Value::string(data.find("scope") ? data.find("scope")->str : GOOGLE_SCOPES);
    long expires = data.find("expires_in") ? static_cast<long>(data.find("expires_in")->num) : 3600;
    saved["expires_at"] = tj::Value::number(static_cast<double>(std::time(nullptr) + expires));
    write_private(oauth_path(), saved);
}

static std::string oauth_access_token(tj::Value &saved) {
    const tj::Value *access = saved.find("access_token");
    const tj::Value *expires = saved.find("expires_at");
    if (access && access->is_string() && expires && expires->num > std::time(nullptr) + 60)
        return access->str;
    const tj::Value *refresh = saved.find("refresh_token");
    const tj::Value *client = saved.find("client_id");
    if (!refresh || !refresh->is_string() || !client || !client->is_string())
        throw TitanError("Google sign-in expired. Run `titan-ai auth google` again.");
    std::map<std::string, std::string> form = {
        {"grant_type", "refresh_token"},
        {"refresh_token", refresh->str},
        {"client_id", client->str},
    };
    const tj::Value *secret = saved.find("client_secret");
    if (secret && secret->is_string() && !secret->str.empty()) form["client_secret"] = secret->str;
    tj::Value fresh;
    try {
        fresh = http::json_request("POST", GOOGLE_TOKEN_URL, {}, http::form_encode(form), 30);
    } catch (const HttpError &e) {
        throw TitanError("Google sign-in expired (" + std::string(e.what())
                         + "). Run `titan-ai auth google` again.");
    }
    const tj::Value *token = fresh.find("access_token");
    if (!token || !token->is_string())
        throw TitanError("Google token refresh failed. Run `titan-ai auth google` again.");
    for (const auto &pair : fresh.obj) saved[pair.first] = pair.second;
    long expires_in = fresh.find("expires_in") ? static_cast<long>(fresh.find("expires_in")->num) : 3600;
    saved["expires_at"] = tj::Value::number(static_cast<double>(std::time(nullptr) + expires_in));
    write_private(oauth_path(), saved);
    return token->str;
}

static std::string google_adc_token() {
    if (!fs::exists(adc_path())) return "";
    tj::Value adc = read_json_file(adc_path());
    const tj::Value *type = adc.find("type");
    const tj::Value *refresh = adc.find("refresh_token");
    if (!type || type->str != "authorized_user" || !refresh || !refresh->is_string()) return "";
    std::map<std::string, std::string> form = {
        {"grant_type", "refresh_token"},
        {"refresh_token", refresh->str},
        {"client_id", adc.find("client_id") ? adc.find("client_id")->str : ""},
        {"client_secret", adc.find("client_secret") ? adc.find("client_secret")->str : ""},
    };
    try {
        tj::Value fresh = http::json_request("POST", GOOGLE_TOKEN_URL, {}, http::form_encode(form), 30);
        const tj::Value *token = fresh.find("access_token");
        return token && token->is_string() ? token->str : "";
    } catch (const std::runtime_error &) {
        return "";
    }
}

static std::pair<std::string, std::string> oauth_client(const tj::Value &cfg) {
    std::string id = first_env({"GOOGLE_CLIENT_ID"});
    if (id.empty()) id = cfg_string(cfg, {"google_oauth", "client_id"}, "");
    if (id.empty())
        throw TitanError("No Google OAuth client ID. Create a Desktop app OAuth client in Google Cloud, "
                         "then set google_oauth.client_id in `titan-ai config edit` or GOOGLE_CLIENT_ID. "
                         "See `titan-ai docs`.");
    std::string secret = env("GOOGLE_CLIENT_SECRET");
    if (secret.empty()) secret = cfg_string(cfg, {"google_oauth", "client_secret"}, "");
    return {id, secret};
}

static void try_open(const std::string &url) {
    if (std::system(("xdg-open '" + url + "' >/dev/null 2>&1 &").c_str()) == -1) { /* ignore */ }
}

static void auth_google_loopback(const tj::Value &cfg) {
    auto [client_id, secret] = oauth_client(cfg);
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) throw TitanError("cannot create loopback socket");
    int yes = 1;
    setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));
    sockaddr_in addr{};
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    addr.sin_port = 0;
    if (bind(fd, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) < 0) {
        close(fd);
        throw TitanError("cannot bind loopback socket: " + std::string(std::strerror(errno)));
    }
    listen(fd, 1);
    socklen_t len = sizeof(addr);
    getsockname(fd, reinterpret_cast<sockaddr *>(&addr), &len);
    int port = ntohs(addr.sin_port);
    std::string redirect = "http://127.0.0.1:" + std::to_string(port) + "/oauth2callback";

    unsigned char random_buffer[48];
    random_bytes(random_buffer, sizeof(random_buffer));
    std::string verifier = b64url(random_buffer, sizeof(random_buffer));
    std::string challenge = pkce_challenge(verifier);
    std::string state = b64url(random_buffer, 24);

    std::map<std::string, std::string> params = {
        {"response_type", "code"}, {"client_id", client_id}, {"redirect_uri", redirect},
        {"scope", GOOGLE_SCOPES}, {"state", state}, {"code_challenge", challenge},
        {"code_challenge_method", "S256"}, {"access_type", "offline"}, {"prompt", "consent"},
    };
    std::string query;
    for (const auto &pair : params) query += http::escape(pair.first) + "=" + http::escape(pair.second) + "&";
    if (!query.empty()) query.pop_back();
    std::string url = std::string(GOOGLE_AUTH_URL) + "?" + query;

    std::cout << "Sign in with Google to enable Gemini and Google Search grounding.\n"
              << "  Open: " << cyan(url) << "\n"
              << "  Waiting for the browser callback on 127.0.0.1:" << port << " ...\n";
    try_open(url);

    std::string received;
    auto deadline = std::time(nullptr) + 300;
    while (std::time(nullptr) < deadline) {
        pollfd pfd{fd, POLLIN, 0};
        int ready = poll(&pfd, 1, 5000);
        if (ready <= 0) continue;
        int client = accept(fd, nullptr, nullptr);
        if (client < 0) continue;
        char buf[4096];
        ssize_t n = read(client, buf, sizeof(buf));
        if (n > 0) received.assign(buf, static_cast<size_t>(n));
        std::string body = "<h1>Signed in to Titan AI</h1><p>You can close this window.</p>";
        std::string response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\n"
                               "Content-Length: " + std::to_string(body.size())
                               + "\r\nConnection: close\r\n\r\n" + body;
        write(client, response.data(), response.size());
        close(client);
        break;
    }
    close(fd);
    if (received.empty()) throw TitanError("Google sign-in timed out. Try `titan-ai auth google --device`.");

    std::string first_line = received.substr(0, received.find("\r\n"));
    size_t q = first_line.find('?');
    std::string query_string = q == std::string::npos ? "" : first_line.substr(q + 1);
    auto callback = parse_query(query_string);
    if (callback.count("error"))
        throw TitanError("Google sign-in was denied: " + callback["error"]);
    if (callback["state"] != state) throw TitanError("Google sign-in state mismatch; please try again.");
    if (callback["code"].empty()) throw TitanError("Google sign-in returned no authorization code.");

    std::map<std::string, std::string> form = {
        {"grant_type", "authorization_code"}, {"code", callback["code"]},
        {"redirect_uri", redirect}, {"client_id", client_id}, {"code_verifier", verifier},
    };
    if (!secret.empty()) form["client_secret"] = secret;
    tj::Value data = http::json_request("POST", GOOGLE_TOKEN_URL, {}, http::form_encode(form), 30);
    save_token_response(data, client_id, secret);
    std::cout << green("✓ Signed in. Token saved to " + oauth_path().string() + " (mode 0600).") << "\n";
}

static void auth_google_device(const tj::Value &cfg) {
    auto [client_id, secret] = oauth_client(cfg);
    std::map<std::string, std::string> form = {{"client_id", client_id}, {"scope", GOOGLE_SCOPES}};
    if (!secret.empty()) form["client_secret"] = secret;
    tj::Value challenge = http::json_request("POST", GOOGLE_DEVICE_URL, {}, http::form_encode(form), 30);
    std::string code = challenge.find("device_code") ? challenge.find("device_code")->str : "";
    std::string user_code = challenge.find("user_code") ? challenge.find("user_code")->str : "";
    const tj::Value *uri_v = challenge.find("verification_uri");
    if (!uri_v) uri_v = challenge.find("verification_url");
    std::string uri = uri_v ? uri_v->str : "https://google.com/device";
    long interval = challenge.find("interval") ? static_cast<long>(challenge.find("interval")->num) : 5;
    auto deadline = std::time(nullptr) + 600;

    std::cout << "Sign in with Google to enable Gemini and Google Search grounding.\n"
              << "  1. Open " << cyan(uri) << "\n"
              << "  2. Enter code " << cyan(user_code) << "\n";
    if (!std::system("command -v wl-copy >/dev/null 2>&1")) {
        std::system(("printf '%s' '" + user_code + "' | wl-copy >/dev/null 2>&1").c_str());
        std::cout << "     (code copied to the Wayland clipboard)\n";
    }
    try_open(uri);

    while (std::time(nullptr) < deadline) {
        sleep(static_cast<unsigned>(interval));
        std::map<std::string, std::string> poll_form = {
            {"grant_type", "urn:ietf:params:oauth:grant-type:device_code"},
            {"device_code", code}, {"client_id", client_id},
        };
        if (!secret.empty()) poll_form["client_secret"] = secret;
        try {
            tj::Value data = http::json_request("POST", GOOGLE_TOKEN_URL, {}, http::form_encode(poll_form), 30);
            save_token_response(data, client_id, secret);
            std::cout << green("✓ Signed in. Token saved to " + oauth_path().string() + " (mode 0600).") << "\n";
            return;
        } catch (const HttpError &e) {
            const tj::Value *err = e.payload.find("error");
            std::string kind = err && err->is_string() ? err->str : "";
            if (kind == "authorization_pending") continue;
            if (kind == "slow_down") { interval += 5; continue; }
            if (kind == "expired_token") throw TitanError("The sign-in code expired. Run the command again.");
            throw TitanError("Google sign-in failed: " + std::string(e.what()));
        }
    }
    throw TitanError("Google sign-in timed out. Run the command again.");
}

// ── provider calls ───────────────────────────────────────────────────────────

struct Turn { std::string role, text; };
struct Options {
    std::string system;
    int max_tokens = 2048;
    bool has_temp = false;
    double temperature = 0;
    double timeout = 120;
};
struct Result { std::string text; tj::Value raw; std::string model; };

static std::string auth_header(const std::string &value) { return "Bearer " + value; }

static Result call_openai(const std::string &prompt, const std::vector<Turn> &history,
                          const Options &opts, const tj::Value &cfg, const std::string &override) {
    std::string key = api_key(cfg, "openai");
    if (key.empty()) throw TitanError("OpenAI API key missing. Run `titan-ai setup` or set OPENAI_API_KEY.");
    std::string model = model_for(cfg, "openai", override);
    tj::Value messages = tj::Value::array();
    if (!opts.system.empty()) {
        bool reasoning = starts_with(model, "o1") || starts_with(model, "o3") || starts_with(model, "o4")
                         || starts_with(model, "gpt-5") || starts_with(model, "gpt-6")
                         || starts_with(model, "codex");
        tj::Value m = tj::Value::object();
        m["role"] = tj::Value::string(reasoning ? "developer" : "system");
        m["content"] = tj::Value::string(opts.system);
        messages.arr.push_back(m);
    }
    for (const auto &turn : history) {
        tj::Value m = tj::Value::object();
        m["role"] = tj::Value::string(turn.role);
        m["content"] = tj::Value::string(turn.text);
        messages.arr.push_back(m);
    }
    tj::Value user = tj::Value::object();
    user["role"] = tj::Value::string("user");
    user["content"] = tj::Value::string(prompt);
    messages.arr.push_back(user);

    tj::Value payload = tj::Value::object();
    payload["model"] = tj::Value::string(model);
    payload["messages"] = messages;
    if (opts.max_tokens > 0) payload["max_completion_tokens"] = tj::Value::number(opts.max_tokens);
    if (opts.has_temp) payload["temperature"] = tj::Value::number(opts.temperature);
    tj::Value raw = http::json_request(
        "POST", base_for(cfg, "openai") + "/chat/completions",
        {{"Authorization", auth_header(key)}, {"Content-Type", "application/json"}},
        payload.dump(), opts.timeout);
    const tj::Value *text = nullptr;
    const tj::Value *choices = raw.find("choices");
    if (choices && choices->is_array() && !choices->arr.empty()) {
        const tj::Value *message = dig(choices->arr[0], {"message"});
        if (message) text = message->find("content");
    }
    return {text && text->is_string() ? text->str : "", raw, model};
}

static Result call_claude(const std::string &prompt, const std::vector<Turn> &history,
                          const Options &opts, const tj::Value &cfg, const std::string &override) {
    std::string key = api_key(cfg, "claude");
    if (key.empty()) throw TitanError("Anthropic API key missing. Run `titan-ai setup` or set ANTHROPIC_API_KEY.");
    tj::Value messages = tj::Value::array();
    for (const auto &turn : history) {
        tj::Value m = tj::Value::object();
        m["role"] = tj::Value::string(turn.role);
        m["content"] = tj::Value::string(turn.text);
        messages.arr.push_back(m);
    }
    tj::Value user = tj::Value::object();
    user["role"] = tj::Value::string("user");
    user["content"] = tj::Value::string(prompt);
    messages.arr.push_back(user);

    std::string model = model_for(cfg, "claude", override);
    tj::Value payload = tj::Value::object();
    payload["model"] = tj::Value::string(model);
    payload["messages"] = messages;
    payload["max_tokens"] = tj::Value::number(opts.max_tokens > 0 ? opts.max_tokens : 2048);
    if (!opts.system.empty()) payload["system"] = tj::Value::string(opts.system);
    if (opts.has_temp) payload["temperature"] = tj::Value::number(opts.temperature);
    std::string base = base_for(cfg, "claude");
    std::string url = base + (base.size() >= 3 && base.substr(base.size() - 3) == "/v1"
                              ? "/messages" : "/v1/messages");
    tj::Value raw = http::json_request(
        "POST", url,
        {{"x-api-key", key}, {"anthropic-version", "2023-06-01"},
         {"Content-Type", "application/json"}},
        payload.dump(), opts.timeout);
    std::string text;
    const tj::Value *content = raw.find("content");
    if (content && content->is_array())
        for (const auto &block : content->arr) {
            const tj::Value *type = block.find("type");
            const tj::Value *value = block.find("text");
            if (type && type->str == "text" && value && value->is_string()) text += value->str;
        }
    return {text, raw, model};
}

static Result call_gemini(const std::string &prompt, const std::vector<Turn> &history,
                          const Options &opts, const tj::Value &cfg, const std::string &override,
                          bool search) {
    Cred cred = google_credentials(const_cast<tj::Value &>(cfg));
    std::string model = model_for(cfg, "gemini", override);
    std::map<std::string, std::string> headers = {{"Content-Type", "application/json"}};
    if (cred.method == "api_key") headers["x-goog-api-key"] = cred.secret;
    else headers["Authorization"] = auth_header(cred.secret);
    std::string project = first_env({"GOOGLE_CLOUD_PROJECT", "GOOGLE_CLOUD_PROJECT_ID"});
    if (project.empty()) project = cfg_string(cfg, {"google_oauth", "project_id"}, "");
    if (!project.empty()) headers["x-goog-user-project"] = project;

    tj::Value contents = tj::Value::array();
    for (const auto &turn : history) {
        tj::Value c = tj::Value::object();
        tj::Value parts = tj::Value::array();
        tj::Value part = tj::Value::object();
        part["text"] = tj::Value::string(turn.text);
        parts.arr.push_back(part);
        c["role"] = tj::Value::string(turn.role == "assistant" ? "model" : "user");
        c["parts"] = parts;
        contents.arr.push_back(c);
    }
    std::string query = search ? "Use Google Search to answer accurately and cite your sources.\n\n" + prompt : prompt;
    tj::Value c = tj::Value::object();
    tj::Value parts = tj::Value::array();
    tj::Value part = tj::Value::object();
    part["text"] = tj::Value::string(query);
    parts.arr.push_back(part);
    c["role"] = tj::Value::string("user");
    c["parts"] = parts;
    contents.arr.push_back(c);

    tj::Value payload = tj::Value::object();
    payload["contents"] = contents;
    tj::Value generation = tj::Value::object();
    bool has_generation = false;
    if (opts.max_tokens > 0) {
        generation["maxOutputTokens"] = tj::Value::number(opts.max_tokens);
        has_generation = true;
    }
    if (opts.has_temp) {
        generation["temperature"] = tj::Value::number(opts.temperature);
        has_generation = true;
    }
    if (has_generation) payload["generationConfig"] = generation;
    if (!opts.system.empty()) {
        tj::Value instruction = tj::Value::object();
        tj::Value iparts = tj::Value::array();
        tj::Value ipart = tj::Value::object();
        ipart["text"] = tj::Value::string(opts.system);
        iparts.arr.push_back(ipart);
        instruction["parts"] = iparts;
        payload["systemInstruction"] = instruction;
    }
    if (search) {
        tj::Value tools = tj::Value::array();
        tj::Value tool = tj::Value::object();
        tj::Value google_search = tj::Value::object();
        tool["google_search"] = google_search;
        tools.arr.push_back(tool);
        payload["tools"] = tools;
    }

    std::string url = base_for(cfg, "gemini") + "/v1beta/models/" + http::escape(model) + ":generateContent";
    tj::Value raw = http::json_request("POST", url, headers, payload.dump(), opts.timeout);
    const tj::Value *candidates = raw.find("candidates");
    if (!candidates || !candidates->is_array() || candidates->arr.empty())
        throw TitanError("Gemini returned no candidate response");
    const tj::Value *candidate = &candidates->arr[0];
    std::string text;
    const tj::Value *content = candidate->find("content");
    if (content) {
        const tj::Value *parts_v = content->find("parts");
        if (parts_v && parts_v->is_array())
            for (const auto &p : parts_v->arr) {
                const tj::Value *t = p.find("text");
                if (t && t->is_string()) text += t->str;
            }
    }
    const tj::Value *finish = candidate->find("finishReason");
    if (text.empty() && finish && finish->str == "SAFETY")
        throw TitanError("Gemini blocked this response with its safety filters");
    return {text, raw, model};
}

static Result call_provider(const std::string &provider, const std::string &prompt,
                            const std::vector<Turn> &history, const Options &opts,
                            tj::Value &cfg, const std::string &override, bool search) {
    if (provider == "openai") return call_openai(prompt, history, opts, cfg, override);
    if (provider == "claude") return call_claude(prompt, history, opts, cfg, override);
    return call_gemini(prompt, history, opts, cfg, override, search);
}

// ── citations / output ───────────────────────────────────────────────────────

static std::string annotate(const std::string &text, const tj::Value *meta) {
    if (!meta) return text;
    const tj::Value *supports = meta->find("groundingSupports");
    if (!supports || !supports->is_array()) return text;
    std::map<size_t, std::string> inserts;
    for (const auto &support : supports->arr) {
        const tj::Value *indices = support.find("groundingChunkIndices");
        if (!indices || !indices->is_array() || indices->arr.empty()) continue;
        std::string marker;
        for (const auto &i : indices->arr)
            marker += "[" + std::to_string(static_cast<long>(i.num) + 1) + "]";
        const tj::Value *segment = support.find("segment");
        if (!segment) continue;
        const tj::Value *end = segment->find("endIndex");
        if (end && end->is_number()) {
            size_t pos = static_cast<size_t>(end->num);
            if (pos > text.size()) pos = text.size();
            if (inserts[pos].find(marker) == std::string::npos) inserts[pos] += marker;
        }
    }
    std::string out;
    for (size_t i = 0; i <= text.size(); ++i) {
        if (inserts.count(i)) out += inserts[i];
        if (i < text.size()) out += text[i];
    }
    return out;
}

static void print_result(const Result &result, bool as_json, bool search, bool links_only) {
    if (as_json) {
        tj::Value out = tj::Value::object();
        out["provider"] = tj::Value::string(search ? "gemini" : "");
        out["text"] = tj::Value::string(result.text);
        out["raw"] = result.raw;
        std::cout << out.dump(2) << "\n";
        return;
    }
    const tj::Value *candidates = result.raw.find("candidates");
    const tj::Value *meta = nullptr;
    if (candidates && candidates->is_array() && !candidates->arr.empty())
        meta = candidates->arr[0].find("groundingMetadata");
    if (search && meta) {
        std::cout << (links_only ? "" : annotate(result.text, meta)) << "\n";
        const tj::Value *chunks = meta->find("groundingChunks");
        if (chunks && chunks->is_array()) {
            std::cout << "\n" << dim("Sources:") << "\n";
            int i = 0;
            for (const auto &chunk : chunks->arr) {
                const tj::Value *web = chunk.find("web");
                const tj::Value *uri = web ? web->find("uri") : nullptr;
                if (!uri || !uri->is_string()) continue;
                const tj::Value *title = web->find("title");
                std::string host = uri->str;
                size_t scheme = host.find("://");
                if (scheme != std::string::npos) host = host.substr(scheme + 3);
                size_t slash = host.find('/');
                if (slash != std::string::npos) host.resize(slash);
                std::cout << "  " << dim("[" + std::to_string(++i) + "]") << " "
                          << (title && title->is_string() && !title->str.empty() ? title->str : host)
                          << "\n      " << dim(uri->str) << "\n";
            }
        }
        return;
    }
    std::cout << (result.text.empty() ? dim("(empty response)") : result.text) << "\n";
}

// ── CLI ──────────────────────────────────────────────────────────────────────

struct Args {
    std::string command, provider, model, system;
    int max_tokens = 0;
    bool has_temp = false;
    double temperature = 0, timeout = 0;
    bool all = false, json = false, links = false, device = false, auth_setup = false;
    std::vector<std::string> prompt;
    std::string auth_command, config_command, key, value;
};

static void usage() {
    std::cout << "usage: titan-ai [options] [PROMPT]\n"
                 "       titan-ai {ask|search|chat|status|setup|config|auth|docs} ...\n\n"
                 "options:\n"
                 "  -p, --provider NAME   openai/chatgpt, claude/anthropic, gemini/google, auto\n"
                 "  -m, --model NAME      override the configured model\n"
                 "      --system TEXT     system prompt\n"
                 "      --max-tokens N    maximum output tokens\n"
                 "      --temperature N   sampling temperature\n"
                 "      --timeout N       request timeout in seconds\n"
                 "      --all             ask every configured provider\n"
                 "  -j, --json            print the full JSON response\n\n"
                 "auth options:\n"
                 "  --device              use the device-code flow (headless/SSH)\n"
                 "  --setup               guided Google Cloud Desktop-app client setup\n\n"
                 "examples:\n"
                 "  titan-ai 'explain btrfs snapshots'\n"
                 "  titan-ai -p claude 'review this script'\n"
                 "  titan-ai search 'latest Arch Linux news'\n"
                 "  titan-ai auth google --setup\n"
                 "  titan-ai chat\n";
}

static bool is_command(const std::string &s) {
    return s == "ask" || s == "search" || s == "chat" || s == "status" || s == "setup"
           || s == "config" || s == "auth" || s == "docs";
}
static std::vector<std::string> inject_ask(std::vector<std::string> argv) {
    static const std::set<std::string> needs_value = {
        "-p", "--provider", "-m", "--model", "--system", "--max-tokens", "--temperature", "--timeout"
    };
    for (size_t i = 0; i < argv.size();) {
        const std::string &token = argv[i];
        if (needs_value.count(token)) { i += 2; continue; }
        if (token == "--") { argv.insert(argv.begin() + static_cast<long>(i), "ask"); return argv; }
        if (!token.empty() && token[0] == '-' && token != "-") { ++i; continue; }
        if (is_command(token)) return argv;
        argv.insert(argv.begin() + static_cast<long>(i), "ask");
        return argv;
    }
    return argv;
}

static Args parse_args(const std::vector<std::string> &raw) {
    Args args;
    std::vector<std::string> argv = inject_ask(raw);
    for (size_t i = 0; i < argv.size(); ++i) {
        std::string token = argv[i];
        auto value_of = [&](const std::string &name) -> std::string {
            if (token.rfind(name + "=", 0) == 0) return token.substr(name.size() + 1);
            if (i + 1 >= argv.size()) throw TitanError("option " + name + " needs a value");
            return argv[++i];
        };
        if (token == "-h" || token == "--help") { usage(); std::exit(0); }
        if (token == "--version") { std::cout << "titan-ai " << VERSION << "\n"; std::exit(0); }
        else if (token == "-p" || starts_with(token, "--provider=")) args.provider = value_of("--provider");
        else if (token == "-m" || starts_with(token, "--model=")) args.model = value_of("--model");
        else if (token == "--system" || starts_with(token, "--system=")) args.system = value_of("--system");
        else if (token == "--max-tokens" || starts_with(token, "--max-tokens="))
            args.max_tokens = static_cast<int>(std::strtol(value_of("--max-tokens").c_str(), nullptr, 10));
        else if (token == "--temperature" || starts_with(token, "--temperature=")) {
            args.temperature = std::strtod(value_of("--temperature").c_str(), nullptr);
            args.has_temp = true;
        } else if (token == "--timeout" || starts_with(token, "--timeout="))
            args.timeout = std::strtod(value_of("--timeout").c_str(), nullptr);
        else if (token == "--all") args.all = true;
        else if (token == "-j" || token == "--json") args.json = true;
        else if (token == "--links") args.links = true;
        else if (token == "--device") args.device = true;
        else if (token == "--setup") args.auth_setup = true;
        else if (token == "-") { /* stdin marker, handled in run */ }
        else if (token[0] == '-') throw TitanError("unknown option '" + token + "'");
        else if (args.command.empty()) args.command = token;
        else if (args.command == "auth" && args.auth_command.empty()) args.auth_command = token;
        else if (args.command == "config" && args.config_command.empty()) args.config_command = token;
        else if (args.command == "config" && args.key.empty()) args.key = token;
        else if (args.command == "config" && args.value.empty()) args.value = token;
        else args.prompt.push_back(token);
    }
    return args;
}

static Options options_for(const Args &args, const tj::Value &cfg) {
    Options opts;
    const tj::Value *sys = dig(cfg, {"system"});
    opts.system = !args.system.empty() ? args.system
                  : (sys && sys->is_string() ? sys->str : DEFAULT_SYSTEM);
    if (args.max_tokens > 0) opts.max_tokens = args.max_tokens;
    else {
        const tj::Value *t = dig(cfg, {"max_tokens"});
        if (t && t->is_number()) opts.max_tokens = static_cast<int>(t->num);
    }
    const tj::Value *timeout = dig(cfg, {"timeout"});
    opts.timeout = args.timeout > 0 ? args.timeout
                   : (timeout && timeout->is_number() ? timeout->num : 120);
    opts.has_temp = args.has_temp;
    opts.temperature = args.temperature;
    return opts;
}

static std::string prompt_text(const Args &args) {
    std::string joined;
    for (const auto &part : args.prompt) {
        if (!joined.empty()) joined += ' ';
        joined += part;
    }
    if (joined == "-") {
        std::string input, line;
        while (std::getline(std::cin, line)) { input += line + "\n"; }
        joined = trim(input);
    }
    return joined;
}

static int cmd_ask(const Args &args, tj::Value &cfg, const std::string &prompt) {
    if (args.all) {
        Options opts = options_for(args, cfg);
        bool any = false;
        for (const auto &provider : PROVIDERS) {
            if (!has_credentials(cfg, provider)) {
                std::cout << dim("── " + label(provider) + ": no credentials, skipped") << "\n";
                continue;
            }
            std::cout << "\n" << cyan("══ " + label(provider) + " ══") << "\n";
            try {
                Result r = call_provider(provider, prompt, {}, opts, cfg, args.model, false);
                std::cout << dim("model: " + r.model) << "\n";
                print_result(r, args.json, false, false);
                any = true;
            } catch (const std::runtime_error &e) {
                std::cout << red(e.what()) << "\n";
            }
        }
        if (!any) throw TitanError("no provider answered the prompt");
        return 0;
    }
    std::string provider = resolve_provider(cfg, args.provider);
    Result r = call_provider(provider, prompt, {}, options_for(args, cfg), cfg, args.model, false);
    print_result(r, args.json, false, false);
    return 0;
}

static int cmd_search(const Args &args, tj::Value &cfg, const std::string &prompt) {
    std::string provider = "gemini";
    if (!args.provider.empty()) {
        auto requested = normalise_provider(args.provider);
        if (requested) provider = *requested;
    }
    if (provider != "gemini") throw TitanError("Google Search grounding is only available through Gemini (-p gemini)");
    try {
        Result r = call_gemini(prompt, {}, options_for(args, cfg), cfg, args.model, true);
        print_result(r, args.json, true, args.links);
        return 0;
    } catch (const HttpError &e) {
        if (e.status == 403 || e.status == 429)
            std::cerr << dim("hint: Gemini Search grounding uses your Gemini/Cloud quota. "
                             "Check https://aistudio.google.com/app/apikey and "
                             "https://console.cloud.google.com/apis/dashboard; grounding "
                             "may be billed separately on some models.") << "\n";
        throw;
    }
}

static int cmd_chat(const Args &args, tj::Value &cfg) {
    std::string provider = resolve_provider(cfg, args.provider);
    Options opts = options_for(args, cfg);
    std::vector<Turn> history;
    std::cout << cyan("Titan AI chat") << " - " << label(provider)
              << " (" << dim("type /help for commands, Ctrl-D to exit") << ")\n";
    std::string line;
    while (true) {
        std::cout << dim("titan-ai") << "[" << provider << "]> " << std::flush;
        if (!std::getline(std::cin, line)) { std::cout << "\n"; return 0; }
        line = trim(line);
        if (line.empty()) continue;
        if (line[0] == '/') {
            std::string command = line.substr(1);
            size_t space = command.find(' ');
            std::string verb = space == std::string::npos ? command : command.substr(0, space);
            std::string value = space == std::string::npos ? "" : trim(command.substr(space + 1));
            if (verb == "quit" || verb == "exit" || verb == "q") return 0;
            if (verb == "help") {
                std::cout << dim("/provider NAME  /model NAME  /system TEXT  /search QUERY  /clear  /quit") << "\n";
            } else if (verb == "clear") {
                history.clear();
                std::cout << dim("Conversation cleared.") << "\n";
            } else if (verb == "provider") {
                provider = resolve_provider(cfg, value);
                std::cout << dim("Switched to " + label(provider) + ".") << "\n";
            } else if (verb == "model") {
                if (value.empty()) std::cout << dim("model: " + model_for(cfg, provider, "")) << "\n";
                else { const_cast<Args &>(args).model = value; std::cout << dim("model set to " + value + ".") << "\n"; }
            } else if (verb == "system") {
                opts.system = value;
                std::cout << dim(value.empty() ? "System prompt cleared." : "System prompt updated.") << "\n";
            } else if (verb == "search") {
                if (value.empty()) { std::cout << dim("Usage: /search <query>") << "\n"; continue; }
                try { print_result(call_gemini(value, {}, opts, cfg, args.model, true), false, true, false); }
                catch (const std::runtime_error &e) { std::cout << red(e.what()) << "\n"; }
            } else std::cout << red("Unknown command: /" + verb) << "\n";
            continue;
        }
        history.push_back({ "user", line });
        try {
            Result r = call_provider(provider, line, {history.begin(), history.end() - 1}, opts,
                                     cfg, args.model, false);
            std::cout << (r.text.empty() ? dim("(empty response)") : r.text) << "\n";
            history.push_back({ "assistant", r.text });
        } catch (const std::runtime_error &e) {
            std::cout << red(e.what()) << "\n";
            history.pop_back();
        }
    }
}

static std::string read_secret(const std::string &prompt) {
    std::cout << prompt << std::flush;
    termios old{};
    tcgetattr(0, &old);
    termios no_echo = old;
    no_echo.c_lflag &= ~ECHO;
    tcsetattr(0, TCSANOW, &no_echo);
    std::string value;
    std::getline(std::cin, value);
    tcsetattr(0, TCSANOW, &old);
    std::cout << "\n";
    return trim(value);
}

// Prompt for the one thing Google cannot ship inside an OS image: the user's
// own Desktop-app OAuth client ID. Stored locally with 0600 permissions.
static std::pair<std::string, std::string> ensure_oauth_client(tj::Value &cfg) {
    std::string id = env("GOOGLE_CLIENT_ID");
    if (!id.empty()) return {id, env("GOOGLE_CLIENT_SECRET")};
    const tj::Value *stored = dig(cfg, {"google_oauth", "client_id"});
    if (stored && stored->is_string() && !stored->str.empty()) return oauth_client(cfg);

    std::cout << "\n" << cyan("Google sign-in needs an OAuth client ID") << "\n"
              << dim("  Google does not let an OS ship a shared sign-in secret. Create a free") << "\n"
              << dim("  Desktop app OAuth client in your Google Cloud project and paste its ID.") << "\n"
              << dim("  One-time steps: titan-ai docs") << "\n";
    std::cout << "OAuth client ID (blank to cancel): " << std::flush;
    std::string entered;
    std::getline(std::cin, entered);
    entered = trim(entered);
    if (entered.empty())
        throw TitanError("Google sign-in cancelled. Run `titan-ai docs` for the setup steps.");
    cfg["google_oauth"]["client_id"] = tj::Value::string(entered);
    std::string secret = read_secret("Client secret (blank for Desktop/public clients): ");
    if (!secret.empty()) cfg["google_oauth"]["client_secret"] = tj::Value::string(secret);
    cfg["default_provider"] = tj::Value::string("gemini");
    save_config(cfg);
    std::cout << green("✓ Client ID saved to " + config_path().string() + ".") << "\n";
    return {entered, secret};
}

static int cmd_setup(Args &, tj::Value &cfg) {
    std::cout << cyan("Titan AI setup") << dim("  (values stay in your user config, never in the ISO)") << "\n";
    if (!dig(cfg, {"providers"})) cfg["providers"] = tj::Value::object();

    std::cout << "\n" << cyan("1. Google sign-in (recommended)") << "\n"
              << dim("   Google account access for Gemini chat and Google Search in Kitty.") << "\n"
              << dim("   Run `titan-ai docs` for the one-time Google Cloud client setup.") << "\n";
    std::cout << "Enable Google sign-in now? [Y/n]: " << std::flush;
    std::string answer;
    std::getline(std::cin, answer);
    answer = lower(trim(answer));
    if (answer.empty() || answer == "y" || answer == "yes") {
        try {
            ensure_oauth_client(cfg);
            std::cout << "Sign in with Google now? [y/N]: " << std::flush;
            std::getline(std::cin, answer);
            answer = lower(trim(answer));
            if (answer == "y" || answer == "yes") {
                std::cout << "Headless/device flow? [y/N]: " << std::flush;
                std::getline(std::cin, answer);
                answer = lower(trim(answer));
                if (answer == "y" || answer == "yes") auth_google_device(cfg);
                else auth_google_loopback(cfg);
            }
        } catch (const TitanError &e) {
            std::cout << red(e.what()) << "\n"
                      << dim("  You can retry with: titan-ai auth google") << "\n";
        }
        cfg["default_provider"] = tj::Value::string("gemini");
    }

    std::cout << "\n" << cyan("2. Gemini API key (optional fallback)") << "\n";
    std::string current = api_key(cfg, "gemini");
    std::string key = read_secret("Gemini API key (blank to skip, current: " + mask(current) + "): ");
    if (!key.empty()) {
        cfg["providers"]["gemini"]["api_key"] = tj::Value::string(key);
        cfg["default_provider"] = tj::Value::string("gemini");
    }
    std::cout << dim("  ChatGPT/Claude need their own API keys; this flow focuses on Google/Gemini.") << "\n";

    save_config(cfg);
    std::cout << green("✓ Saved " + config_path().string() + " (mode 0600).") << "\n"
              << dim("  Next: titan-ai search '...'  or press Ctrl+Shift+S in Kitty") << "\n";
    return 0;
}

static int cmd_status(const Args &, tj::Value &cfg) {
    std::cout << cyan("TITAN AI status") << "  " << dim("config: " + config_path().string()) << "\n";
    const tj::Value *def = dig(cfg, {"default_provider"});
    std::cout << "  " << dim("default provider:") << " "
              << (def && def->is_string() && !def->str.empty() ? def->str : "auto (Gemini first)")
              << "\n";
    for (const auto &p : PROVIDERS) {
        std::string auth = "not configured";
        if (p == "gemini") {
            if (fs::exists(oauth_path())) auth = "Google sign-in (primary)";
            else if (!api_key(cfg, p).empty()) auth = "API key (fallback)";
            else if (fs::exists(adc_path())) auth = "gcloud ADC";
        } else if (has_credentials(cfg, p)) {
            auth = "API key";
        }
        std::string name = label(p);
        name.resize(24, ' ');
        std::cout << "  " << name << " " << dim("model:") << " " << model_for(cfg, p, "")
                  << "  " << dim("auth:") << " " << auth << "\n";
    }
    if (fs::exists(oauth_path())) {
        tj::Value saved = read_json_file(oauth_path());
        const tj::Value *exp = saved.find("expires_at");
        double left = exp ? exp->num - std::time(nullptr) : 0;
        std::cout << "  " << dim("Google token:") << " " << (left > 0 ? "valid" : "expired")
                  << " (" << std::abs(static_cast<long>(left)) / 60 << " min)\n";
    }
    return 0;
}

static std::optional<tj::Value> coerce(const std::string &value) {
    std::string v = lower(value);
    if (v == "true" || v == "yes" || v == "on") return tj::Value::boolean(true);
    if (v == "false" || v == "no" || v == "off") return tj::Value::boolean(false);
    if (v == "null" || v == "none") return tj::Value::null();
    char *end = nullptr;
    long i = std::strtol(value.c_str(), &end, 10);
    if (*end == '\0') return tj::Value::number(i);
    double d = std::strtod(value.c_str(), &end);
    if (*end == '\0') return tj::Value::number(d);
    return tj::Value::string(value);
}

static int cmd_config(const Args &args, tj::Value &cfg) {
    std::string action = args.config_command.empty() ? "show" : args.config_command;
    if (action == "path") { std::cout << config_path().string() << "\n"; return 0; }
    if (action == "show") {
        // Mask secrets by rebuilding a copy.
        tj::Value copy = cfg;
        for (auto &pair : copy.obj)
            if (pair.first == "providers" && pair.second.is_object())
                for (auto &p : pair.second.obj)
                    if (const tj::Value *k = p.second.find("api_key"); k && !k->str.empty())
                        p.second["api_key"] = tj::Value::string(mask(k->str));
        if (const tj::Value *o = copy.find("google_oauth"); o && o->is_object()) {
            tj::Value masked = *o;
            if (const tj::Value *s = o->find("client_secret"); s && !s->str.empty())
                masked["client_secret"] = tj::Value::string(mask(s->str));
            copy["google_oauth"] = masked;
        }
        std::cout << copy.dump(2) << "\n";
        return 0;
    }
    if (action == "edit") {
        std::string editor = env("EDITOR", env("VISUAL", "nvim"));
        char *const argv[] = {const_cast<char *>(editor.c_str()),
                              const_cast<char *>(config_path().c_str()), nullptr};
        execvp(argv[0], argv);
        throw TitanError("cannot launch editor '" + editor + "'");
    }
    if (action == "set" || action == "unset") {
        if (args.key.empty()) throw TitanError("config " + action + " needs a key");
        std::stringstream ss(args.key);
        std::string part;
        std::vector<std::string> keys;
        while (std::getline(ss, part, '.')) keys.push_back(part);
        tj::Value *node = &cfg;
        for (size_t i = 0; i + 1 < keys.size(); ++i) {
            if (keys[i].empty()) throw TitanError("invalid config key");
            tj::Value *next = &(*node)[keys[i]];
            if (!next->is_object()) *next = tj::Value::object();
            node = next;
        }
        if (action == "unset") {
            if (node->is_object()) node->obj.erase(keys.back());
        } else {
            auto value = coerce(args.value);
            (*node)[keys.back()] = value ? *value : tj::Value::null();
        }
        save_config(cfg);
        std::cout << green("✓ " + config_path().string() + " updated.") << "\n";
        return 0;
    }
    throw TitanError("usage: titan-ai config {show|path|edit|set KEY VALUE|unset KEY}");
}

static void guide_google_setup(const Args &args, tj::Value &cfg) {
    std::cout << cyan("Google sign-in guided setup") << "\n"
              << dim("  This is not an app to install — it is a one-time 'Desktop app' OAuth client")
              << "\n"
              << dim("  in your own Google Cloud account. No secret goes into the ISO.") << "\n\n";

    std::cout << cyan("Step 1 — Sign in to Google Cloud") << "\n"
              << "  Use the Gmail you want Gemini/Search tied to:\n"
              << "  https://console.cloud.google.com/\n\n";
    std::cout << cyan("Step 2 — Create or select a project") << "\n"
              << "  Suggested name: archtitan-ai. Select it in the top project bar.\n\n";
    std::cout << cyan("Step 3 — Enable the API") << "\n"
              << "  https://console.developers.google.com/apis/library\n"
              << "  Search 'Gemini API' (older name: 'Generative Language API') -> Enable.\n\n";
    std::cout << cyan("Step 4 — Configure the consent screen") << "\n"
              << "  Google Auth platform -> Branding: name 'ArchTitan TITAN AI', your emails.\n"
              << "  Audience -> External; add your Gmail under Test users.\n"
              << "  Data Access -> add these scopes:\n"
              << "    https://www.googleapis.com/auth/cloud-platform\n"
              << "    https://www.googleapis.com/auth/generative-language.retriever\n"
              << "  Publishing status 'Testing' is fine; you'll see an unverified warning.\n\n";
    std::cout << cyan("Step 5 — Create the Desktop app client") << "\n"
              << "  https://console.developers.google.com/auth/clients\n"
              << "  Create client -> Application type: Desktop app\n"
              << "  Name: ArchTitan TITAN AI -> Create -> copy the Client ID.\n\n";
    std::cout << dim("  Loopback redirect (http://127.0.0.1:<port>/oauth2callback) is automatic;")
              << "\n"
              << dim("  you do not need to type a redirect URI anywhere.") << "\n\n";

    std::cout << "Open the console and Clients page now? [Y/n]: " << std::flush;
    std::string answer;
    std::getline(std::cin, answer);
    answer = lower(trim(answer));
    if (answer.empty() || answer == "y" || answer == "yes") {
        try_open("https://console.cloud.google.com/");
        try_open("https://console.developers.google.com/auth/clients");
        std::cout << dim("  Opened two tabs. Return here after copying the Client ID.\n\n");
    }

    try {
        ensure_oauth_client(cfg);
    } catch (const TitanError &e) {
        std::cout << dim(std::string("  ") + e.what()) << "\n";
        return;
    }

    std::cout << "Google Cloud project ID (optional, for billing headers; blank to skip): " << std::flush;
    std::string project;
    std::getline(std::cin, project);
    project = trim(project);
    if (!project.empty()) {
        cfg["google_oauth"]["project_id"] = tj::Value::string(project);
        save_config(cfg);
    }

    std::cout << "Sign in with Google now? [Y/n]: " << std::flush;
    std::getline(std::cin, answer);
    answer = lower(trim(answer));
    if (answer.empty() || answer == "y" || answer == "yes") {
        bool use_device = args.device;
        if (!use_device) {
            std::cout << "Headless/device flow? [y/N]: " << std::flush;
            std::getline(std::cin, answer);
            answer = lower(trim(answer));
            use_device = (answer == "y" || answer == "yes");
        }
        if (use_device) auth_google_device(cfg);
        else auth_google_loopback(cfg);
        std::cout << green("✓ Google sign-in stored.") << "\n";
    }

    std::cout << "\n" << green("✓ Google sign-in setup complete.") << "\n"
              << dim("  Verify:  titan-ai status") << "\n"
              << dim("  Search:  titan-ai search 'latest Arch Linux news'") << "\n"
              << dim("  Kitty:   Ctrl+Shift+S") << "\n";
}

static int cmd_auth(const Args &args, tj::Value &cfg) {
    if (args.auth_command == "google") {
        if (args.auth_setup) {
            guide_google_setup(args, cfg);
            return 0;
        }
        ensure_oauth_client(cfg);
        if (args.device) auth_google_device(cfg);
        else auth_google_loopback(cfg);
        return 0;
    }
    if (args.auth_command == "status") return cmd_status(args, cfg);
    if (args.auth_command == "logout") {
        if (fs::exists(oauth_path())) {
            fs::remove(oauth_path());
            std::cout << green("✓ Google sign-in removed.") << "\n";
        } else std::cout << dim("No Google sign-in stored.") << "\n";
        return 0;
    }
    throw TitanError("usage: titan-ai auth {google|status|logout}");
}

static void print_google_guide() {
    std::cout << R"GUIDE(TITAN AI — Google sign-in and Gemini Search

Google sign-in is the primary way to use Gemini chat and Google Search grounding in
ArchTitan. A Gemini API key is an optional fallback. ChatGPT and Claude need their own
API keys and are not part of this sign-in flow.

1) ONE-TIME GOOGLE CLOUD SETUP
   a. Open https://console.cloud.google.com/ and select or create a project.
   b. Enable "Generative Language API" for that project.
   c. Google Auth platform -> Audience: External; add your own email under Test users.
   d. Google Auth platform -> Clients -> Create Client:
        Application type: Desktop app
        Name: ArchTitan TITAN AI
   e. Copy the Client ID (and Client secret, if Google shows one).

2) GIVE IT TO TITAN AI
   titan-ai auth google --setup    # guided checklist, opens console tabs, stores the ID
   titan-ai auth google            # prompts for the ID if none is stored, then opens a browser
   titan-ai auth google --device   # headless/SSH: visit the printed URL, enter the code
   titan-ai status                 # should show "Google sign-in (primary)"

   You can also pre-store the ID:
   titan-ai config set google_oauth.client_id '...apps.googleusercontent.com'

3) USE IT
   titan-ai search 'latest Arch Linux news'
   titan-ai 'explain btrfs snapshots'
   Press Ctrl+Shift+S in Kitty to open the search window — no command to type.

4) FALLBACK: GEMINI API KEY
   Get a key from Google AI Studio, then run `titan-ai setup` and paste it at the
   Gemini API key prompt, or export GEMINI_API_KEY.

5) ABOUT GOOGLE SEARCH AND COST
   `titan-ai search` uses Gemini's google_search grounding — the official Google
   path for new projects. It returns an AI answer with real Google citations.
   It is NOT a separate free "Google Search API": Google closed Custom Search JSON
   API to new customers, and raw search scraping breaks Google's terms.

   Gemini has a limited free tier; search grounding may be billed separately from
   plain text generation on some models. Check quota and billing here:
     https://aistudio.google.com/app/apikey
     https://console.cloud.google.com/apis/dashboard

   `titan-ai search --links QUERY` prints only the cited source URLs.

6) TROUBLESHOOTING
   - "Google hasn't verified this app" is expected for a personal client:
     choose Advanced -> Continue.
   - access_denied: make sure your email is listed under Test users.
   - Redirect URI mismatch: the OAuth client must be a Desktop app (loopback is allowed).
   - Token expired: run `titan-ai auth google` again; tokens refresh automatically
     while a refresh token is available.

Nothing secret is shipped in the ISO. The OAuth client ID is public; your tokens and
API keys stay in ~/.config/archtitan with mode 0600.
)GUIDE";
}

static int run(int argc, char **argv) {
    Args args = parse_args(std::vector<std::string>(argv + 1, argv + argc));
    if (args.command == "docs") {
        print_google_guide();
        return 0;
    }
    tj::Value cfg = load_config();
    std::string prompt = prompt_text(args);

    if (args.command == "setup") return cmd_setup(args, cfg);
    if (args.command == "status") return cmd_status(args, cfg);
    if (args.command == "auth") return cmd_auth(args, cfg);
    if (args.command == "config") return cmd_config(args, cfg);
    if (args.command == "chat") return cmd_chat(args, cfg);
    if (args.command == "search") {
        if (prompt.empty()) throw TitanError("search needs a query");
        return cmd_search(args, cfg, prompt);
    }
    if (args.command == "ask") {
        if (prompt.empty()) throw TitanError("ask needs a prompt");
        return cmd_ask(args, cfg, prompt);
    }
    if (prompt.empty()) return cmd_chat(args, cfg);
    return cmd_ask(args, cfg, prompt);
}

int main(int argc, char **argv) {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    std::srand(static_cast<unsigned>(std::time(nullptr)));
    try {
        return run(argc, argv);
    } catch (const TitanError &e) {
        std::cerr << red("titan-ai:") << " " << e.what() << "\n";
        return 2;
    } catch (const HttpError &e) {
        std::cerr << red("titan-ai:") << " HTTP " << e.status << ": " << e.what() << "\n";
        return 2;
    } catch (const std::runtime_error &e) {
        std::cerr << red("titan-ai:") << " " << e.what() << "\n";
        return 2;
    }
}
