#pragma once

#include <string>
#include <vector>

namespace umake
{

struct RuleInfo;

struct Rule {
    typedef std::vector<std::string> StringList;
    bool multiple;
    StringList target;
    StringList dependencies, order_only_dependencies;
    StringList commands;

    Rule(StringList* target, StringList* dependencies, StringList* order_only_dependencies, bool multiple, StringList* commands);
    ~Rule();

    std::string gen(bool debug = false);
    void gen_body(std::stringstream& ss, bool dd = false, bool debug = false);
    // RuleInfo* info;
};


struct parser
{
    void* lexer;
    std::vector<Rule*> rules;

    ~parser() { for (auto rule : rules) delete rule; }

    void Parse(std::string input);
    void add(Rule* rule) { rules.push_back(rule); }
};


} // namespace umake

