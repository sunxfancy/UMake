#include <iostream>
#include <fstream>
#include <string>
#include <tuple>
#include "parser.h"

std::tuple<std::string, std::string, std::string> load_file(const char *filename)
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
    return {content[0], content[1], content[2]};
}




int main(int argc, char **argv)
{
    std::cout << "umake " << argv[1] << std::endl;
    auto [header, src, library] = load_file(argv[1]);
    std::cout << src << std::endl;

    umake::parser parser;
    parser.Parse(src);

    

    std::ofstream file(argv[1]);
    file << header << src << library << std::endl;

    for (auto rule : parser.rules) {
        file << rule->gen() << std::endl;
    }
    // output generated parts
    file << std::endl << "endif" << std::endl;
    return 0;
}
