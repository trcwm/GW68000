/*

    Splitbin 

*/

#include <fstream>
#include <iostream>
#include <filesystem>
#include <cstdlib>

int main(int argc, const char *argv[])
{
    std::cout << "Splitbin version 1.0\n";

    if (argc < 2)
    {
        std::cerr << "Usage: splitbit <binfile>\n";
        return EXIT_FAILURE;
    }

    std::filesystem::path infilePath{argv[1]};
    if (infilePath.extension() != ".bin")
    {
        std::cerr << "Splitbin works on .bin files only!\n";
        return EXIT_FAILURE;
    }

    std::ifstream infile(infilePath, std::ios::binary);
    if (!infile.is_open())
    {
        std::cerr << "Cannot open bin file " << argv[1] << "\n";
        return EXIT_FAILURE;
    }

    auto lowerFilename = infilePath.stem();
    auto upperFilename = infilePath.stem();
    lowerFilename += "_lower.txt";
    upperFilename += "_upper.txt";
    
    std::ofstream lowerFile(lowerFilename);
    std::ofstream upperFile(upperFilename);

    bool genVHDL = argc > 2;
    int index = 0;
    while(!infile.eof())
    {
        char buffer[100];
        uint8_t mybyte;

        if (!genVHDL)
        {
            infile.read((char*)&mybyte, 1);
            sprintf(buffer, "%02X\n", mybyte);
            upperFile << buffer;

            infile.read((char*)&mybyte, 1);
            sprintf(buffer, "%02X\n", mybyte);
            lowerFile << buffer;
        }
        else
        {
            infile.read((char*)&mybyte, 1);
            sprintf(buffer, "    ram_content(%d) <= x\"%02X\"\n", index, mybyte);
            upperFile << buffer;

            infile.read((char*)&mybyte, 1);
            sprintf(buffer, "    ram_content(%d) <= x\"%02X\"\n", index, mybyte);
            lowerFile << buffer;

            index++;
        }
    }

    return EXIT_SUCCESS;
}

