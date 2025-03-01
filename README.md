# Usage

Just run command:

```sh
zig build run
```

To build a Linux version release binary:

```sh
zig build -Dtarget=x86_64-linux-gnu
```

To build a size-optimized Linux release binary:

```sh
zig build -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseSmall
```

# TODO List

- [ ] Add many objects.
- [ ] Add many methods.
- [ ] No wait more if timeout.
- [x] Handle updates.
- [ ] Make a logger.
- [x] Build a OpenRouter API client.
- [ ] Check grammar in prompt.txt.
