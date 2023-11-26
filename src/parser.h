#pragma once

#include <map>
#include <string>
#include <vector>

namespace umake {

struct Rule {
    typedef std::vector<std::string>           StringList;
    typedef std::map<std::string, std::string> StringMap;
    bool                                       multiple;
    StringList                                 target;
    StringList dependencies, order_only_dependencies;
    StringList commands;
    StringMap  attrs;

    Rule(StringList *target, StringList *dependencies,
         StringList *order_only_dependencies, bool multiple,
         StringList *commands, StringMap *attrs);
    ~Rule();

    std::string gen(bool debug = false);
    void gen_body(std::stringstream &ss, bool dd = false, bool debug = false);
};

struct parser {
    void               *lexer;
    const char         *lexer_buffer;
    std::vector<Rule *> rules;

    ~parser() {
        for (auto rule : rules)
            delete rule;
    }

    void Parse(std::string input);
    void add(Rule *rule) { rules.push_back(rule); }
};

} // namespace umake
