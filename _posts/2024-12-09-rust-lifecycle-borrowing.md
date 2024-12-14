---
layout: post
title: Understanding Borrowing and Lifetimes in Rust
categories: [Rust, Programming]
excerpt: Rust's borrowing and lifetime rules ensure memory safety without garbage collection. This post explores shared and exclusive borrows, lifetime management, and the role of the borrow checker in preventing data races and dangling references using some basic examples.
---

# Understanding Borrowing and Lifetimes in Rust

One of Rust’s core promises is _memory safety without garbage collection_. This is enforced at compile time through the concepts of _ownership_ and _borrowing_. Borrowing in Rust ensures that data accessed through references is always valid, preventing dangling pointers and other memory errors that can plague lower-level languages.

In this article, we’ll start with basic references and gradually move to more advanced concepts like exclusive borrowing and lifetime management. By the end, you’ll understand how Rust’s borrow checker ensures correctness and safety throughout your codebase.

## Basic Borrowing: Shared References

In Rust, you don’t typically pass raw pointers around. Instead, you work with references that adhere to strict borrowing rules. A shared reference (`&T`) allows you to read the referenced data but not modify it. Rust enforces these rules at compile time, ensuring that the data you’re referencing remains valid for the entire lifetime of the reference.

```rust
fn print_value(value: &i32) {
    println!("The value is: {}", value);
}

fn basic_shared_reference_example() {
    let x = 10;
    // Borrow `x` as an immutable (shared) reference
    print_value(&x);
    // `x` is still owned by main, `print_value` just borrowed it.
    println!("x is still accessible: {}", x);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_shared_reference() {
        basic_shared_reference_example();
    }
}

```

In this example, `print_value` takes a reference to an `i32`. By passing `&x`, we create a _shared reference_: `print_value` can read `x` but not modify it. After `print_value` returns, `x` is still valid and owned by main. There’s no copying or transferring of ownership here—just a temporary borrow.

## Introducing Mutable References: Exclusive Borrows

While shared references (`&T`) allow multiple readers at once, mutable references (`&mut T`) grant exclusive write access to a piece of data. A mutable reference ensures that there’s exactly one active mutable reference to a piece of data at any time. This prevents data races and ensures that when you have a mutable reference, no one else can modify or even read that data through another reference.

```rust
fn increment(value: &mut i32) {
    *value += 1;
}

fn basic_mutable_reference_example() {
    let mut x = 5;
    // Create a mutable reference to `x`
    increment(&mut x);
    increment(&mut x);
    println!("x after increment: {}", x);
    //This will print 7
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_mutable_reference() {
        basic_mutable_reference_example();
    }
}

```

In the snippet above, `increment` takes an exclusive borrow of `x`. While `increment` is running, no other references to `x` may exist. After `increment` returns, it gives back the exclusive borrow, and we can read `x` again.

## The Borrow Checker: Ensuring Safety

Rust’s compiler [uses a borrow checker](https://doc.rust-lang.org/1.8.0/book/references-and-borrowing.html#meta) to verify these constraints at compile time. The borrow checker prevents you from compiling code that would create invalid or conflicting references.

For example, Rust won’t allow a scenario where you have both a mutable reference and a shared reference alive at the same time:

```rust
fn basic_invalid_borrow_example() {
    let mut data = String::from("Hello");
    let r1 = &data;       // Shared borrow
    let r2 = &mut data;   // Attempt an exclusive borrow

    // This won't compile:
    // error[E0502]: cannot borrow `data` as mutable because it is also borrowed as immutable
    println!("{}", r1);
    println!("{}", r2);
    
    //You could have any number of immutable references, or only 1 mutable reference.
    //This is a restriction placed by the borrow checker to prevent race conditions and other problems.
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_invalid_borrow() {
        basic_invalid_borrow_example();
    }
}

```

The borrow checker catches this at compile time, preventing invalid memory access and potential data races.

## Lifetimes: Tying Borrows to Scopes

Every reference in Rust has a lifetime, a scope over which the reference is valid. Typically, lifetimes are inferred automatically, so you rarely need to specify them. But understanding the concept is crucial for more advanced scenarios, such as writing generic functions that accept references.

When a reference is created, its lifetime can’t outlive the data it points to. For example:

```rust
fn basic_scoped_borrow_example() {
    let r;            // Declare a reference `r`
    {
        let x = 10;   // `x` lives until the end of this block
        r = &x;       // Borrow `x`
    }
    // `x` no longer exists here, so `r` is dangling!
    // println!("{}", r); // This would be invalid.

    // The borrow checker ensures that code like this doesn't compile.
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_basic_scoped_borrow() {
        basic_scoped_borrow_example();
    }
}

```

The compiler ensures that `r` cannot outlive `x`. By enforcing these lifetime rules, Rust prevents dangling references. In practice, you’ll mostly rely on inference, but you may encounter advanced situations where explicit lifetimes are required.  It is possible to define explicit lifetimes, but it won't be covered in this post.

## Putting It All Together: Shared and Exclusive Borrows in Practice

Let’s look at a more complex example that mixes multiple references safely:

```rust
fn sum(slice: &[i32]) -> i32 {
    slice.iter().sum()
}

fn push_value(vec: &mut Vec<i32>, val: i32) {
    vec.push(val);
}


#[cfg(test)]
mod tests {
    use std::fmt::format;
    use super::*;

    #[test]
    fn test_borrowing() {
        let mut numbers = vec![1, 2, 3];

        // Shared reference to `numbers` for reading
        let total = sum(&numbers);
        println!("The total is: {}", total);

        // Now we need to modify `numbers`. We must ensure no active shared references remain.
        push_value(&mut numbers, 4);

        // After `push_value` completes, `numbers` is still accessible.
        println!("After push: {:?}", numbers);
    }

}
```

The output of this is

```text
The total is: 6
After push: [1, 2, 3, 4]
```

In a future blog post I will cover `Mutex` and `RwLock` which are used to share data between threads.  These are more advanced topics that build on the concepts of borrowing and lifetimes that we have covered in this post.  Stay tuned for that post.