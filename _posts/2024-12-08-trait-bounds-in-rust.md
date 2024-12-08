---
layout: post
title: Trait Bounds in Rust
categories: [Rust, Programming]
excerpt: Learn how to use trait bounds in Rust to write more flexible and reusable code
---

# Exploring Trait Bounds in Rust

When working with generics in Rust, you often need to specify constraints on the types being used. These constraints are *trait bounds*, and they ensure that a type parameter `T` has certain capabilities (like printing, comparing, or performing arithmetic operations). By adding trait bounds, you can write functions and structs that are more flexible and still benefit from Rust’s robust compile-time checks.

## What Are Trait Bounds?

Consider that you have a generic function `print_value<T>(value: T)`. If this function attempts to print `value`, Rust needs to know that `value` can indeed be printed. In other words, the type `T` must implement the `Display` trait. By writing `fn print_value<T: Display>(value: T)`, you’re telling the compiler that `T` must implement the `Display` trait. If you try to pass in a type that doesn’t implement `Display`, you’ll get a compile error.

## A Simple Example
```rust
fn print_value<T: std::fmt::Display>(value: T) {
    println!("{}", value);
}
```
In this example, the trait bound T: Display ensures that any type passed to print_value must have a Display implementation. For example, a &str works perfectly because strings can be printed. However, i32 does not implement Display by default—it does implement Debug, but that’s a different trait.

## Multiple Trait Bounds
What if you need more than one constraint? For instance, maybe you want to both print values and compare them. You can specify multiple trait bounds using `+`:

```rust
fn compare_and_print<T: std::fmt::Display + PartialOrd>(a: T, b: T) {
    println!("Comparing {} and {}", a, b);
    if a < b {
        println!("{} is less than {}", a, b);
    } else if a > b {
        println!("{} is greater than {}", a, b);
    } else {
        println!("{} is equal to {}", a, b);
    }
}
```

Now `T` must implement both `Display` and `PartialOrd`. This means it must be printable and orderable. Strings and many numeric types fit this description, but not all types do.

## Using `where` Clauses for Readability

As trait bounds become more complex, you can use a where clause to keep your function signatures cleaner:

```rust
fn describe_pair<T>(t0: T, t1: T)
where
    T: Display + PartialOrd
{
    println!("We have a pair: ({}, {})", t0, t1);
    println!("Is t < u? {}", t1 < t0);
}
```

The `where` clause moves the trait constraints out of the function signature and into a dedicated space, improving code readability.

## Custom Traits and Trait Bounds

You can also define your own traits and use trait bounds to require that a type implement them. For example, consider the custom Summable trait:

```rust
trait Summable {
    fn sum(&self) -> i32;
}

impl Summable for Vec<i32> {
    fn sum(&self) -> i32 {
        self.iter().sum()
    }
}
```

We could then write a function that only accepts types that implement Summable:

```rust
fn print_sum<T: Summable>(item: T) {
    println!("The sum is {}", item.sum());
}
```

But let's say we want to print the item as well as the sum. We can add a trait bound for Display as well:

```rust
fn print_sum<T: Summable + std::fmt::Display>(item: T) {
    println!("The sum of {} is {}", item, item.sum());
}
```

`Vec<i32>` doesn't implement `Display`. We can't add a trait bound for a type that we don't own. To work around this, we can create a wrapper type that does implement `Display`.  The reason we have to use a wrapper is that we can't implement a trait for a type that is not defined in the current crate.  This is a limitation of Rust's orphan rule.

```rust
struct DisplayVec(Vec<i32>);
impl std::fmt::Display for VecWrapper {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        write!(f, "{:?}", self.0)
    }
}

impl Summable for DisplayVec {
    fn sum(&self) -> i32 {
        self.0.iter().sum()
    }
}
```

Side Note: the reason the .0 is in there is that we defined DisplayVec as a tuple struct.  This means that it has a single field, which is the Vec<i32>.  The .0 is how we access that field.  We could have been more explicit and defined DisplayVec as a struct with a single field, but the tuple struct is more concise and convinient.

Now we can call our print_sum function with a Vec<i32>:

```rust
fn main() {
    let v = DisplayVec(vec![1, 2, 3]);
    print_sum(v);
}
```

## Conclusion and testing


```rust
// We'll explore:
// 1. Simple trait bounds (e.g., Display).
// 2. Multiple trait bounds (e.g., Display + PartialOrd).
// 3. Using `where` clauses for more readable trait bounds.
// 4. Defining custom traits (e.g., Summable) and requiring them via trait bounds.
// 5. Working around the orphan rule by creating a wrapper type that implements Display,
//    so we can use it with our Summable trait-bound functions.
//
// Each of these examples is covered in detail with tests at the bottom.

// Bring `Display` into scope for convenience.
use std::fmt::Display;

// 1. A simple function that takes any type that implements Display.
//    This ensures that the type `T` can be printed with `println!`.
fn print_value<T: Display>(value: T) {
    println!("{}", value);
}

// 2. A function that requires multiple trait bounds.
//    Here, `T` must implement both `Display` (so we can print it)
//    and `PartialOrd` (so we can compare values).
fn compare_and_print<T: Display + PartialOrd>(a: T, b: T) {
    println!("Comparing {} and {}", a, b);
    if a < b {
        println!("{} is less than {}", a, b);
    } else if a > b {
        println!("{} is greater than {}", a, b);
    } else {
        println!("{} is equal to {}", a, b);
    }
}

// 3. Using `where` clauses for readability.
//    This function compares a pair of values.  Both values
//    must be of the same type `T`, which must implement `Display` and `PartialOrd`.
//    NOTE: We cannot accept two different types here, even if they both implement the required traits.
//    This is because the `PartialOrd` comparison requires the types to be the same.
//    You couldn't compare an `i32` and a `String`, for example.
fn describe_pair<T>(t0: T, t1: T)
where
    T: Display + PartialOrd
{
    println!("We have a pair: ({}, {})", t0, t1);
    println!("Is t < u? {}", t1 < t0);
}

// 4. A custom trait: Summable.
//    Any type implementing Summable must have a `sum()` method that returns an i32.
trait Summable {
    fn sum(&self) -> i32;
}

// Implement Summable for Vec<i32>, summing all elements.
impl Summable for Vec<i32> {
    fn sum(&self) -> i32 {
        self.iter().sum()
    }
}

// A function that uses our custom trait Summable.
// For now, this only requires Summable, so it can print the sum.
fn print_sum<T: Summable>(item: T) {
    println!("The sum is {}", item.sum());
}

// However, if we want to print the item itself in addition to the sum, we need `Display` as well.
// This function now requires T to implement both Summable and Display.
fn print_sum_and_value<T: Summable + Display>(item: T) {
    println!("The sum of {} is {}", item, item.sum());
}

// 5. Creating a wrapper type to implement Display for a vector,
//    because Vec<i32> doesn't implement Display by default.
//    By creating a wrapper type that we control, we can implement Display on it,
//    satisfying the orphan rule.
struct DisplayVec(Vec<i32>);

impl Display for DisplayVec {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        // Using {:?} to print the Vec<i32>, since it's conveniently Debug-printable.
        write!(f, "{:?}", self.0)
    }
}

// We also need Summable for DisplayVec so that we can use print_sum_and_value on it.
impl Summable for DisplayVec {
    fn sum(&self) -> i32 {
        self.0.iter().sum()
    }
}

// The `.0` field access notation is because DisplayVec is a tuple struct with a single field.
// If we had defined it as `struct DisplayVec { inner: Vec<i32> }` then we'd access
// the vector as `self.inner`. The tuple struct is more concise.

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_simple_trait_bound() {
        // &str implements Display, so this works fine.
        print_value("Hello, world!");

        // i32 does not implement Display by default. If you try uncommenting the line below,
        // it will fail to compile:
        // print_value(42);
    }

    #[test]
    fn test_multiple_trait_bounds() {
        // &str implements Display and PartialOrd.
        compare_and_print("apple", "banana");

        // f64 implements PartialOrd and Display (through to_string internally).
        compare_and_print(3.14, 2.71);
    }

    #[test]
    fn test_where_clause() {
        // Both &str and i32 implement the necessary traits (Display and PartialOrd).
        describe_pair("alpha", "beta");
        describe_pair(10, 42);
    }

    #[test]
    fn test_custom_trait_simple() {
        // Vec<i32> implements Summable, but not Display.
        let numbers = vec![1, 2, 3, 4, 5];
        print_sum(numbers);
    }

    #[test]
    fn test_custom_trait_with_display() {
        let numbers = vec![1, 2, 3];

        // If we try this directly, it won't compile:
        // print_sum_and_value(numbers);
        // Because Vec<i32> doesn't implement Display.

        // Instead, use our wrapper type that implements Display and Summable:
        let display_numbers = DisplayVec(numbers);
        print_sum_and_value(display_numbers);

        // This now works since DisplayVec implements both Display and Summable.
    }
}

```