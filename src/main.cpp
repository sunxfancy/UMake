#include <iostream>
#include <fstream>
#include <string>
#include <tuple>
#include <filesystem>
#include "parser.h"

auto load_file(const char *filename)
{
    std::ifstream file(filename);
    std::string content[3];
    std::string str;
    int i = 0;
    while(std::getline(file, str))
    {
        if (str == "endif # End of the editable source code")
            i++;
        content[i] += (str + "\n");
        if (str == "#-------------------- DO NOT EDIT BELOW THIS LINE --------------------#") 
            break;
        if (str == "ifeq (0,1) # The following is the editable source code") 
            i++;
    }
    return make_tuple(content[0], content[1], content[2]);
}

bool file_not_exist(const char *filename)
{
    return !std::filesystem::exists(filename);
}

void check_args(int argc, char **argv)
{
    if (argc < 2 || file_not_exist(argv[1]) ) {
        std::cout << "Usage: umake <filename>" << std::endl;
        if (argc < 2)
            std::cout << "Error: No filename specified" << std::endl;
        else {
            if (!(argv[1] == std::string("-h") || argv[1] == std::string("--help")))
                std::cout << "Error: File " << argv[1] << " not found" << std::endl;
        }
        std::cout << "PWD: " << std::filesystem::current_path() << std::endl;
        exit(0);
    }
}

int main(int argc, char **argv)
{
    check_args(argc, argv);

    std::cout << "umake " << argv[1] << std::endl;
    auto [header, src, library] = load_file(argv[1]);

    umake::parser parser;
    parser.Parse(src);

    std::ofstream file(argv[1]);
    file << header << src << library << std::endl;

    file << "ifeq ($(DEBUG),1)" << std::endl;
    for (auto rule : parser.rules) {
        file << rule->gen(true) << std::endl;
    }
    file << "else" << std::endl;
    for (auto rule : parser.rules) {
        file << rule->gen() << std::endl;
    }
    file << "endif" << std::endl;

    // output generated parts
    file << std::endl << "endif" << std::endl;
    return 0;
}
