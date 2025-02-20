# Usage

Just run command:

```sh
zig build run
```

To build a Linux version release binary:

```sh
zig build-exe src/main.zig -O ReleaseSmall -fstrip -fsingle-threaded -target x86_64-linux
```

# TODO List

- [ ] Add many objects.
- [ ] Add many methods.
- [ ] No wait more if timeout.
- [ ] Tests don't print but assume/assert.
- [ ] Change `Bot.invoke` to just input content because we can get the method by content's type.
- [ ] Handle updates.
