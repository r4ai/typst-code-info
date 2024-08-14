#import "../../plugin.typ": init-code-info, code-info, parse-diff-code

#show: init-code-info.with()

#code-info(
  caption: [code block with line numbers],
  show-line-numbers: true,
)
```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

#code-info(
  diff: true,
  show-line-numbers: true,
  always-show-lines: (1, 14, 15),
)
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
```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn sub(a: i32, b: i32) -> i32 {
    let c = a - b;
    c
}

pub fn mul(a: i32, b: i32) -> i32 {
    a * b
}

pub fn div(a: i32, b: i32) -> i32 {
    a / b
}
```

#code-info(
  diff: true,
  always-show-lines: (1, 14, 15),
)
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
```rust
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}

pub fn sub(a: i32, b: i32) -> i32 {
    let c = a - b;
    c
}

pub fn mul(a: i32, b: i32) -> i32 {
    a * b
}

pub fn div(a: i32, b: i32) -> i32 {
    a / b
}
```

#parse-diff-code(
  always-show-lines: (1, 2, 15),
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
  ```,
  ```rust
  pub fn add(a: i32, b: i32) -> i32 {
      a + b
  }

  pub fn sub(a: i32, b: i32) -> i32 {
      let c = a - b;
      c
  }

  pub fn mul(a: i32, b: i32) -> i32 {
      a * b
  }

  pub fn div(a: i32, b: i32) -> i32 {
      a / b
  }
  ```,
)
