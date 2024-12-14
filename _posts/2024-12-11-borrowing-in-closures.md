---
layout: post
title: Understanding Borrowing in Closures and Variable Capturing in Rust
categories: [Rust, Programming]
excerpt: "Closures in Rust capture variables from their surrounding environment using one of three methods: by reference (&T), by mutable reference (&mut T), or by value (T). The capture method is inferred by the compiler based on how the closure uses the variable. Closures can implement one of three traits (Fn, FnMut, or FnOnce), depending on whether they read, modify, or consume the captured variable. The move keyword forces ownership of variables into the closure, which is essential for async tasks and multi-threaded contexts. This article provides detailed examples of these concepts, highlighting key distinctions between borrowing, mutability, and capture mechanics."
---

# Understanding Borrowing in Closures and Variable Capturing in Rust

In our previous discussions on borrowing and lifetimes, we explored how Rust’s borrow checker ensures memory safety by enforcing strict rules on references. This time, we’ll take a deeper look at how _closures_ fit into the picture.

Closures are anonymous functions that can capture variables from their surrounding environment. While closures might look simple, the rules governing how they borrow these variables are quite intricate. Understanding these borrowing rules will help you write cleaner, safer, and more efficient Rust code—especially as you start working with asynchronous code or building more complex abstractions.

## The Basics: How Closures Capture Variables

In Rust, closures can capture variables from their enclosing scope in one of three ways:

1. **By reference (`&T`)**: The closure borrows the variable, allowing read-only access.
2. **By mutable reference (`&mut T`)**: The closure takes an exclusive, mutable borrow of the variable, enabling modification.
3. **By value (moving `T`)**: The closure takes ownership of the variable, moving it into the closure’s environment.

The compiler knows which capture method to use. If you only read it, the closure captures by reference (if possible). If you modify it, the closure needs to borrow it mutably. If you move it (e.g., by returning it from the closure or passing it into a function that takes ownership), the closure will capture it by value.

```rust
fn run_example() {

    let x = 10;

    // Only reads `x`, so captures by shared reference.
    // Notice this closure does not have the mut modifier.  It doesn't need it
    // If you tried to modify x in this closure, you would get a compile error
    let closure_ref = || println!("x is: {}", x);

    closure_ref(); // Can still call multiple times

    let mut y = 5;

    // Modifies `y`, so captures by mutable reference.
    let mut closure_mut = || y += 1;

    closure_mut();
    closure_mut(); // Can still call multiple times as long as `y` is in scope

    println!("y after closure: {}", y);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_capture_by_reference() {
        run_example();
    }
}

```

In this example code, we have two closures: `closure_ref` and `closure_mut`. The first closure captures `x` by shared reference because it only reads the value. The second closure captures `y` by mutable reference because it modifies it. The compiler infers these capture methods based on how the variables are used inside the closures.

One point of clarity, when I say `the compiler infers` you may notice that I had to define `closure_mut` as `mut`.  This is because we need to define the closure itself as mutable, since it has its own state (`y`) and that state needs to be tracked and the compiler needs to be told about that.  Whether the values being captured by the closure are captured as `&T` or `&mut T` is inferred by the compiler based on how the values are used in the closure.

## Moving Values into Closures

Here is an example of a closure that moves a value into its environment:

```rust
fn run_example() {
    let s = String::from("Hello");
    let closure_own = move || {
        // `s` is moved into the closure's environment.
        println!("s inside closure: {}", s);
    };
    
    // `s` is no longer accessible here, as it's been moved.
    // Uncommenting the line below will result in a compilation error.
    // println!("s outside closure: {}", s);
    closure_own();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_move_closure() {
        run_example();
    }
}

```

The `move` keyword ensures the closure takes ownership of `s` rather than just borrowing it. Without `move`, the closure would reference a value that no longer exists when it runs, leading to invalid memory access. By using `move`, we guarantee that the closure fully owns `s` and can safely access it, even after the original scope has ended.

**Important Note** - If `s` were a primitive, or any other type that implements the `Copy` trait, then the closure would capture the value by copying it.  So you could still access `s` after the closure but any modifications that the closure made to `s` would not be reflected in the original `s`.

Here is an example of that.

```rust
fn run_example() {

    let mut y = 5;

    // Notice the move keyword here.  This closure takes ownership of y
    // But since y is Copy, the value this closure
    // takes ownership of is a copy of y, not the original
    let mut closure_mut = move || {
        y += 1
    };

    closure_mut();
    closure_mut();

    println!("y after closure: {}", y);
    //This prints 5, not 7
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_capture_by_reference() {
        run_example();
    }
}
```

This is a significant gotcha that needs to be kept in mind when working with closures in Rust.

## Immutable Borrows After Closure Capture

The same borrowing rules that apply to references also apply to captured variables within closures.  If a closure is defined that only borrows data immutably, such as in the example below that doesn't mutate `data` but only prints it, then the closure only borrows the data by reference, and you can still borrow the data immutably elsewhere in the code.  Rust doesn't `move` the data because the compiler knows it doesn't have to since it isn't mutating it.  

```rust
fn run_example() {
    let data = vec![1, 2, 3];

    // This closure doesn't specify 'move' or 'mut', so it borrows `data` by reference.
    // Side note, if it did specify `mut` you would have to define the data reference above as mutable
    let closure = || {
        println!("{:?}", data);
    };

    let r = &data; //This line would fail if closure was FnMut

    closure(); // Uses mutable borrow
    println!("{:?}", r);
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_immutable_borrow() {
        run_example();
    }
}

```

## Closure Traits: `Fn`, `FnMut`, and `FnOnce`

Rust defines three closure traits that describe how closures capture and use variables:

* `Fn`: Closure can be called multiple times without mutating or consuming captured variables (captures by shared reference).
* `FnMut`: Closure can be called multiple times and may mutate the captured variables (captures by mutable reference).
* `FnOnce`: Closure can be called at least once but might consume captured variables (captures by value).

The compiler automatically infers which trait a closure implements based on how it captures and uses variables. This inference determines what kind of arguments you can pass the closure to. For example, methods like `Iterator::map` expect an `Fn` closure because they shouldn’t modify the environment, while `Iterator::for_each` can work with `FnMut` closures if you need to mutate state as you iterate.

Examples of these were given above
 
## Capturing Variables in Async Closures

With async programming, closures often need to `move` their environment into async tasks. This is where move closures shine. They ensure that all captured variables are owned by the closure and thus are available throughout the async task’s lifetime.

**Note**: This example uses the `tokio` crate for async programming.  Async programming is a large topic and won't be covered in depth here.  You can add `tokio` to your `Cargo.toml` file to use it in your project.

```rust 
use tokio::time::{sleep, Duration};

#[tokio::main]
async fn main() {
    let msg = String::from("Hello from async closure");
    let task = tokio::spawn(async move {
        // `msg` is moved here so it can safely live throughout the async block.
        sleep(Duration::from_secs(1)).await;
        println!("{}", msg);
    });

    // `msg` is no longer accessible here.
    task.await.unwrap();
}
```

By using `move`, you avoid potential borrowing issues where a reference might outlive the environment it was borrowed from.

The code would not compile if you removed the `move` keyword from the closure because the closure would try to borrow `msg` by reference, which would be invalid in an async context.

## Conclusion and Next Steps

Closures in Rust are powerful tools, allowing you to write concise, expressive code. But under the hood, Rust enforces strict borrowing rules, ensuring that closures never introduce memory unsafety. By understanding how closures capture variables—whether by reference, mutable reference, or by value—you can write code that’s both flexible and free of data races.

In a future article, we’ll explore interior mutability and how `RefCell` and `Cell` let you work around some of Rust’s compile-time borrowing checks when you need more complex patterns. Stay tuned to continue your journey into the depths of Rust’s ownership and borrowing model!

