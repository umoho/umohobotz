# Tests

## `test_openrouter.zig`

To run this program, use:

```sh
cp tests/test_openrouter.zig ..
zig build-exe test_openrouter.zig -target x86_64-linux
```

Then, set environment variables:

```sh
export OPENROUTER_API_KEY=<your-api-key>
QUESTION="What is the capital of the moon?" ./test_openrouter
```

Clear output files after running the program:

```sh
rm test_openrouter
rm test_openrouter.o
rm test_openrouter.zig
```
