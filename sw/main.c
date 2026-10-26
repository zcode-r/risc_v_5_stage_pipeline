int main() {
    int a = 0;
    int b = 1;
    int c = 0;

    // Calculate the 7th Fibonacci number
    for (int i = 2; i <= 7; i++) {
        c = a + b;
        a = b;
        b = c;
    }

    // Return value is stored in register x10 (a0)
    return c;
}