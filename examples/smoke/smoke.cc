#include "answer.h"
#include <iostream>
#include <numeric>
#include <stdexcept>
#include <vector>

#ifndef __FILC__
#error This application requires Fil-C.
#endif

int main() {
    std::vector<int> values{10, 20, 12};
    if (std::accumulate(values.begin(), values.end(), 0) != answer()) return 1;
    try {
        throw std::runtime_error("Fil-C C++ runtime: OK");
    } catch (const std::exception& error) {
        std::cout << error.what() << '\n';
        return 0;
    }
    return 2;
}
