#include "parser.h"

#include <algorithm>
#include <cstdint>
#include <sstream>
#include <string>
#include <regex>
#include "bison.tab.hpp"
#include "zeroerr.h"

extern void yylex_init(void** scanner);
extern void umake_scan_string(const char* str, struct umake::parser* P);

namespace umake
{


Rule::~Rule() {
    // delete info;
}


Rule::Rule(StringList* target, StringList* dependencies, StringList* order_only_dependencies, bool multiple, StringList* commands) {
    this->target = *target;
    delete target;
    if (dependencies != nullptr) {
        this->dependencies = *dependencies;
        delete dependencies;
    }
    if (order_only_dependencies != nullptr) {
        this->order_only_dependencies = *order_only_dependencies;
        delete order_only_dependencies;
    }
    if (commands != nullptr) {
        this->commands = *commands;
        delete commands;
    }
    this->multiple = multiple;

    // info = new RuleInfo();
}


static std::vector<std::string> find_var(std::string target) {
    std::vector<std::string> vars;
    std::smatch pieces_match;
    static const std::regex var_regex("%\\(([a-zA-Z0-9\-_]+)\\)");
    while (std::regex_search(target, pieces_match, var_regex)) {
        CHECK(pieces_match.size() == 2);
        vars.push_back(pieces_match[1].str());
        target = pieces_match.suffix();
    }
    return vars;
}

static std::string replace_var(std::string target) {
    std::string result;
    std::smatch pieces_match;
    static const std::regex var_regex("%\\(([a-zA-Z0-9\-_]+)\\)");
    std::string res = std::regex_replace(target, var_regex, "$($1_IT)");
    if (res[res.length()-1] == '/') {
        // is a directory
        res += ".complete";
    }
    return res;
}

static std::string convert_double_dollar(std::string s) {
    static const std::regex var_regex("\\$");
    return std::regex_replace(s, var_regex, "$$$$");
}

struct ShellInfo {
    std::vector<std::string> input_files,output_files,input_dirs,output_dirs;

    void append(std::vector<std::string>& buf, const std::regex& re, std::string s) {
        std::smatch pieces_match;
        while (std::regex_search(s, pieces_match, re)) {
            CHECK(pieces_match.size() == 2);
            buf.push_back(pieces_match[1].str());
            s = pieces_match.suffix();
        }
    }

    std::string get_input_output(std::string cmd) {
        static const std::regex fi_regex("<FI:([^>]+)>"), fo_regex("<FO:([^>]+)>"), di_regex("<DI:([^>]+)>"), do_regex("<DO:([^>]+)>");
        append(input_files,  fi_regex, cmd);
        append(output_files, fo_regex, cmd);
        append(input_dirs,   di_regex, cmd);
        append(output_dirs,  do_regex, cmd);

        cmd = std::regex_replace(cmd, fi_regex, "$1");
        cmd = std::regex_replace(cmd, fo_regex, "$1");
        cmd = std::regex_replace(cmd, di_regex, "$1");
        cmd = std::regex_replace(cmd, do_regex, "$1");

        static const std::regex update_pre("$<([2-9])");
        cmd = std::regex_replace(cmd, update_pre, "$(word $1,$^)");

        return cmd;
    }
};


void Rule::gen_body(std::stringstream& ss, bool dd, bool debug) {
    auto print = zeroerr::getStderrPrinter();
    ss << replace_var(target[0]) << (multiple? "&": "") << ":";
    
    for (auto dep : dependencies) {
        ss << " " << replace_var(dep);
    }

    if (order_only_dependencies.size() > 0) {
        ss << " |";
        for (auto dep : order_only_dependencies) {
            ss << " " << replace_var(dep);
        }
    }

    for (auto cmd : commands) {
        ShellInfo info;
        cmd = info.get_input_output(cmd);
        // print(info.input_dirs);
        // print(info.output_dirs);
        // print(info.input_files);
        // print(info.output_files);
        
        std::string first_line_mkdir;
        std::string first_line_cd;
        // if first line is cd, then cut to two parts
        int p = cmd.find_first_not_of(" \t\v\n\r@-");
        if (p < cmd.size()-1 && cmd[p] == 'c' && cmd[p+1] == 'd' && cmd[p+2] == ' ') {
            int q = cmd.find_first_of('\n', p);
            first_line_mkdir = cmd.substr(0, p) + "mkdir -p " + cmd.substr(p+3, q-(p+3));
            first_line_cd = cmd.substr(0,q);
            cmd = cmd.substr(q);
        }

        std::stringstream s;
        s << first_line_mkdir;
        s << first_line_cd;
        for (auto name : info.input_files)
            s << std::endl << "\t$(call check_file_exist," << name << ")";
        for (auto name : info.input_dirs)
            s << std::endl << "\t$(call check_dir_exist," << name << ")";
        for (auto name : info.output_files)
            s << std::endl << "\t$(call make_sure_parent_dir_exist," << name << ")";
        for (auto name : info.output_dirs)
            s << std::endl << "\t$(call make_sure_parent_dir_exist," << name << ")";
        if (!debug) s << cmd;
        else { // generate debug commands
            for (auto name : info.output_files)
                s << std::endl << "\ttouch " << name;
            for (auto name : info.output_dirs)
                s << std::endl << "\tmkdir " << name;
        }
        for (auto name : info.output_files)
            s << std::endl << "\t$(call check_file_exist," << name << ")";
        for (auto name : info.output_dirs)
            s << std::endl << "\t$(call check_dir_exist," << name << ")";
        s << std::endl << "\t$(DEFAULT_ACTION)";

        if (dd) ss << convert_double_dollar(s.str());
        else ss << s.str();
    }
    ss << std::endl << std::endl;
}


std::string Rule::gen(bool debug) {
    auto print = zeroerr::getStderrPrinter();
    CHECK(target.size() == 1);
    std::stringstream ss;
    
    auto vars = find_var(target[0]);
    // print(target[0]);
    // print(vars);

    static int i = 0;
    if (vars.size() > 0) {
        ss << "define " << "GENERATE_" << (++i) << std::endl;
    }
    gen_body(ss, vars.size() > 0, debug);
    if (vars.size() > 0) {
        ss << "endef" << std::endl;

        for (auto var : vars) {
            ss << "$(foreach " << var << "_IT, $(" << var << "),";
        }
        ss << "$(eval $(call GENERATE_" << i << "))";
        for (auto var : vars) {
            ss << ")";
        }
        ss << std::endl;
    }

    return ss.str();
}

void parser::Parse(std::string input) {
    dbg("Parsing input");
    yylex_init(&lexer);
    umake_scan_string(input.c_str(), this);
    yyparse(lexer, this);
    dbg(this->rules);
}

} // namespace umake