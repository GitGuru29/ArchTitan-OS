#pragma once
#include <curl/curl.h>

#include <map>
#include <stdexcept>
#include <string>

#include "json.hpp"

struct HttpResult {
    long status = 0;
    std::string body;
};

struct HttpError : std::runtime_error {
    long status;
    tj::Value payload;
    HttpError(long code, const std::string &message, tj::Value data)
        : std::runtime_error(message), status(code), payload(std::move(data)) {}
};

namespace http {

inline size_t write_cb(char *ptr, size_t size, size_t nmemb, void *userdata) {
    auto *out = static_cast<std::string *>(userdata);
    out->append(ptr, size * nmemb);
    return size * nmemb;
}

inline std::string escape(const std::string &value) {
    CURL *curl = curl_easy_init();
    if (!curl) return value;
    char *out = curl_easy_escape(curl, value.c_str(), static_cast<int>(value.size()));
    std::string result = out ? out : value;
    curl_free(out);
    curl_easy_cleanup(curl);
    return result;
}

inline std::string form_encode(const std::map<std::string, std::string> &form) {
    std::string out;
    for (const auto &pair : form) {
        if (!out.empty()) out += '&';
        out += escape(pair.first) + '=' + escape(pair.second);
    }
    return out;
}

inline HttpResult request(const std::string &method, const std::string &url,
                          const std::map<std::string, std::string> &headers,
                          const std::string &body, double timeout) {
    CURL *curl = curl_easy_init();
    if (!curl) throw std::runtime_error("failed to initialise libcurl");

    curl_slist *list = nullptr;
    for (const auto &pair : headers)
        list = curl_slist_append(list, (pair.first + ": " + pair.second).c_str());
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, list);
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST, method.c_str());
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, 1L);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL, 1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, static_cast<long>(timeout));
    curl_easy_setopt(curl, CURLOPT_USERAGENT, "titan-ai/2.0");
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_cb);
    if (method != "GET") {
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, body.data());
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, static_cast<long>(body.size()));
    }

    HttpResult result;
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &result.body);
    CURLcode rc = curl_easy_perform(curl);
    if (rc == CURLE_OK)
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &result.status);
    curl_slist_free_all(list);
    curl_easy_cleanup(curl);

    if (rc != CURLE_OK) {
        std::string host = url;
        auto pos = host.find("://");
        if (pos != std::string::npos) host = host.substr(pos + 3);
        pos = host.find('/');
        if (pos != std::string::npos) host.resize(pos);
        throw std::runtime_error("cannot reach " + host + ": " + curl_easy_strerror(rc));
    }
    return result;
}

inline tj::Value json_request(const std::string &method, const std::string &url,
                              const std::map<std::string, std::string> &headers,
                              const std::string &body, double timeout) {
    HttpResult res = request(method, url, headers, body, timeout);
    tj::Value parsed = tj::Value::null();
    bool valid = false;
    try {
        if (!res.body.empty()) parsed = tj::Value::parse(res.body);
        valid = true;
    } catch (const std::runtime_error &) {
        valid = res.body.empty();
    }
    if (res.status >= 400) {
        std::string message = res.body.substr(0, 400);
        if (valid && parsed.is_object()) {
            const tj::Value *err = parsed.find("error");
            if (err && err->is_object()) {
                const tj::Value *msg = err->find("message");
                if (msg && msg->is_string()) message = msg->str;
            } else if (err && err->is_string()) {
                message = err->str;
            }
        }
        throw HttpError(res.status, message, parsed);
    }
    if (!valid) throw std::runtime_error("API returned invalid JSON");
    return parsed;
}

} // namespace http
