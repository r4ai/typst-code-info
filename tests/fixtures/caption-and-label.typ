#import "../../plugin.typ": init-code-info, code-info, parse-diff-code

#show: init-code-info.with()

#code-info(
  caption: [A program to display "Hello, world!"],
  label: "hello-world",
)
```rust
pub fn main() {
    println!("Hello, world!");
}
```

According to @hello-world, the program displays "Hello, world!".
