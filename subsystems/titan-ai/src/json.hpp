#pragma once
// Minimal JSON value, parser and serializer for titan-ai (no third-party deps).
#include <cctype>
#include <cstdlib>
#include <map>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace tj {

class Value {
public:
    enum class Type { Null, Bool, Number, String, Array, Object };

    Type type = Type::Null;
    bool b = false;
    double num = 0;
    std::string str;
    std::vector<Value> arr;
    std::map<std::string, Value> obj;

    static Value null() { return Value(); }
    static Value boolean(bool v) { Value x; x.type = Type::Bool; x.b = v; return x; }
    static Value number(double v) { Value x; x.type = Type::Number; x.num = v; return x; }
    static Value string(std::string v) { Value x; x.type = Type::String; x.str = std::move(v); return x; }
    static Value array() { Value x; x.type = Type::Array; return x; }
    static Value object() { Value x; x.type = Type::Object; return x; }

    bool is_null() const { return type == Type::Null; }
    bool is_object() const { return type == Type::Object; }
    bool is_array() const { return type == Type::Array; }
    bool is_string() const { return type == Type::String; }
    bool is_number() const { return type == Type::Number; }

    const Value *find(const std::string &key) const {
        if (type != Type::Object) return nullptr;
        auto it = obj.find(key);
        return it == obj.end() ? nullptr : &it->second;
    }
    Value &operator[](const std::string &key) {
        type = Type::Object;
        return obj[key];
    }
    Value &operator[](size_t i) {
        type = Type::Array;
        if (arr.size() <= i) arr.resize(i + 1);
        return arr[i];
    }
    std::string as_string(const std::string &fallback = "") const {
        return type == Type::String ? str : fallback;
    }
    double as_number(double fallback = 0) const {
        return type == Type::Number ? num : fallback;
    }
    bool as_bool(bool fallback = false) const {
        return type == Type::Bool ? b : fallback;
    }

    std::string dump(int indent = 0) const {
        switch (type) {
        case Type::Null:   return "null";
        case Type::Bool:   return b ? "true" : "false";
        case Type::Number: {
            if (num == static_cast<double>(static_cast<long long>(num)))
                return std::to_string(static_cast<long long>(num));
            return std::to_string(num);
        }
        case Type::String: return quote(str);
        case Type::Array: {
            if (arr.empty()) return "[]";
            std::string out = "[\n";
            for (size_t i = 0; i < arr.size(); ++i) {
                out += std::string(indent + 2, ' ') + arr[i].dump(indent + 2);
                out += (i + 1 < arr.size()) ? ",\n" : "\n";
            }
            return out + std::string(indent, ' ') + "]";
        }
        case Type::Object: {
            if (obj.empty()) return "{}";
            std::string out = "{\n";
            size_t i = 0;
            for (const auto &pair : obj) {
                out += std::string(indent + 2, ' ') + quote(pair.first) + ": "
                       + pair.second.dump(indent + 2);
                out += (++i < obj.size()) ? ",\n" : "\n";
            }
            return out + std::string(indent, ' ') + "}";
        }
        }
        return "null";
    }

    static Value parse(const std::string &text) {
        Parser p(text);
        p.ws();
        Value v = p.value();
        p.ws();
        if (p.i != text.size()) p.fail("trailing data");
        return v;
    }

private:
    struct Parser {
        const std::string &s;
        size_t i = 0;
        explicit Parser(const std::string &text) : s(text) {}

        [[noreturn]] void fail(const std::string &why) const {
            throw std::runtime_error("JSON parse error at byte " + std::to_string(i) + ": " + why);
        }
        void ws() {
            while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
        }
        bool take(char c) {
            if (i < s.size() && s[i] == c) { ++i; return true; }
            return false;
        }
        void expect(char c) {
            if (!take(c)) fail(std::string("expected '") + c + "'");
        }

        static void utf8(std::string &out, unsigned cp) {
            if (cp < 0x80) out += static_cast<char>(cp);
            else if (cp < 0x800) {
                out += static_cast<char>(0xC0 | (cp >> 6));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            } else if (cp < 0x10000) {
                out += static_cast<char>(0xE0 | (cp >> 12));
                out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            } else {
                out += static_cast<char>(0xF0 | (cp >> 18));
                out += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
                out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
                out += static_cast<char>(0x80 | (cp & 0x3F));
            }
        }
        unsigned hex4() {
            if (i + 4 > s.size()) fail("short unicode escape");
            unsigned cp = 0;
            for (int n = 0; n < 4; ++n) {
                char c = s[i++];
                cp <<= 4;
                if (c >= '0' && c <= '9') cp |= static_cast<unsigned>(c - '0');
                else if (c >= 'a' && c <= 'f') cp |= static_cast<unsigned>(c - 'a' + 10);
                else if (c >= 'A' && c <= 'F') cp |= static_cast<unsigned>(c - 'A' + 10);
                else fail("bad unicode escape");
            }
            return cp;
        }
        std::string string() {
            expect('"');
            std::string out;
            while (i < s.size()) {
                char c = s[i++];
                if (c == '"') return out;
                if (c == '\\') {
                    if (i >= s.size()) fail("unterminated escape");
                    char e = s[i++];
                    switch (e) {
                    case '"': out += '"'; break;
                    case '\\': out += '\\'; break;
                    case '/': out += '/'; break;
                    case 'b': out += '\b'; break;
                    case 'f': out += '\f'; break;
                    case 'n': out += '\n'; break;
                    case 'r': out += '\r'; break;
                    case 't': out += '\t'; break;
                    case 'u': {
                        unsigned cp = hex4();
                        if (cp >= 0xD800 && cp <= 0xDBFF && i + 1 < s.size()
                            && s[i] == '\\' && s[i + 1] == 'u') {
                            i += 2;
                            unsigned low = hex4();
                            if (low >= 0xDC00 && low <= 0xDFFF)
                                cp = 0x10000 + ((cp - 0xD800) << 10) + (low - 0xDC00);
                        }
                        utf8(out, cp);
                        break;
                    }
                    default: fail("bad escape");
                    }
                } else {
                    out += c;
                }
            }
            fail("unterminated string");
        }
        Value value() {
            ws();
            if (i >= s.size()) fail("unexpected end");
            char c = s[i];
            if (c == '{') {
                ++i;
                Value v = Value::object();
                ws();
                if (take('}')) return v;
                while (true) {
                    ws();
                    std::string key = string();
                    ws();
                    expect(':');
                    v[key] = value();
                    ws();
                    if (take('}')) return v;
                    expect(',');
                }
            }
            if (c == '[') {
                ++i;
                Value v = Value::array();
                ws();
                if (take(']')) return v;
                while (true) {
                    v.arr.push_back(value());
                    ws();
                    if (take(']')) return v;
                    expect(',');
                }
            }
            if (c == '"') return Value::string(string());
            if (c == 't' && s.compare(i, 4, "true") == 0) { i += 4; return Value::boolean(true); }
            if (c == 'f' && s.compare(i, 5, "false") == 0) { i += 5; return Value::boolean(false); }
            if (c == 'n' && s.compare(i, 4, "null") == 0) { i += 4; return Value::null(); }
            if (c == '-' || std::isdigit(static_cast<unsigned char>(c))) {
                char *end = nullptr;
                double n = std::strtod(s.c_str() + i, &end);
                if (end == s.c_str() + i) fail("bad number");
                i = static_cast<size_t>(end - s.c_str());
                return Value::number(n);
            }
            fail("unexpected character");
        }
    };

    static std::string quote(const std::string &s) {
        static const char *hex = "0123456789abcdef";
        std::string out = "\"";
        for (unsigned char c : s) {
            switch (c) {
            case '"': out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\b': out += "\\b"; break;
            case '\f': out += "\\f"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (c < 0x20) {
                    out += "\\u00";
                    out += hex[c >> 4];
                    out += hex[c & 0xF];
                } else {
                    out += static_cast<char>(c);
                }
            }
        }
        return out + '"';
    }
};

} // namespace tj
