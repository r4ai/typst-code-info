#import "../../plugin.typ": init-code-info, code-info

#show: init-code-info.with()

#code-info(show-line-numbers: true)
```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn sub(a: i32, b: i32) -> i32 {
    a - b
}

pub fn mul(a: i32, b: i32) -> i32 {
    a * b
}

pub fn div(a: i32, b: i32) -> i32 {
    a / b
}
```
