---
layout: post
title: Basic Generics in Rust
categories: [Rust, Programming]
excerpt: Discover how to use generics in Rust to create flexible structs, enums, and functions. This post covers defining generic types, implementing shared functionality, and providing specialized behavior for specific types.
---

# Basic Generics in Rust

Generics in Rust behave differently than generics in other languages such as Java.

In Rust, generics can be used to define the shape of a struct, enum, or function.  The Rust compiler knows that there is a difference between `Container<String>` and `Container<i32>` and you can provide different implementations for each.

## Defining a Generic Struct

To define a generic struct, you can use the following syntax:

```rust
struct Container<T> {
    value: T
}
```

In this example, `T` is a generic type parameter.  You can use any name you want for the generic type parameter, but `T` is a common convention.

We can provide some implementation details that are available to all `Container` types:

```rust
impl<T> Container<T> {
    fn new(value: T) -> Container<T> {
        Container { value }
    }
    
    fn to_string(&self) -> String {
        format!("{:?}", self.value)
    }
}
```

In this example, we define a method `new` that creates a new `Container` with the given value.  We also define a method `to_string` that converts the value to a string.  No matter the type of `T`, these methods will work.

## Defining behavior for specific types

What is interesting about generics in Rust is that you can provide different implementations for different types.  For example, you can provide a specific implementation for `Container<String>`:

```rust
impl Container<String> {
    fn to_uppercase(&self) -> String {
        self.value.to_uppercase()
    }
}
```

In this example, we define a method `to_uppercase` that converts the value to uppercase.  This method is only available for `Container<String>` types.

## Testing it out

```rust

#[cfg(test)]
mod tests {
    use std::fmt::format;
    use super::*;

    #[test]
    fn test_container() {
        let container = Container::new(42);
        // Prints "42"
        println!("{}", container.to_string());
        // This won't compile
        // println!("{}", container.to_uppercase());

        let container = Container::new("hello".to_string());
        println!("{}", container.to_uppercase());
    }

}

```

In this example, we create a `Container` with an integer value and print it.  We then create a `Container` with a string value and convert it to uppercase.


## Conclusion

To summarize, generics in Rust allow you to define the shape of a struct, enum, or function.  You can provide different implementations for different types, which allows you to write more flexible and reusable code.