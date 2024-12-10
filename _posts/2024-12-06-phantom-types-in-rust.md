---
layout: post
title: Phantom Types in Rust
categories: [Rust, Programming]
excerpt: Learn how phantom types in Rust enable compile-time guarantees without runtime overhead. This post explains how to use PhantomData to track type-level information, enforce state transitions, and create safer, more robust APIs.
---

# Using Phantom Types in Rust
In Rust, generics allow us to define flexible and reusable data structures and functions. However, sometimes we need the compiler to understand type-level information without actually holding values of that type at runtime. This is where Phantom Types come into play, making compile-time guarantees easier to encode and enforce.

## What are Phantom Types?
A Phantom Type is a way to "mark" a type using a zero-sized marker, `PhantomData<T>`, without storing a value of that type. This pattern allows the Rust compiler to track a generic type parameter and apply type-checking rules, even though there’s no real data of that type present at runtime.

You include `PhantomData<T>` in a struct to tell the compiler: "This struct is associated with the type `T`, so consider its methods and behavior as if it contained a T." By doing so, you gain the ability to encode state or capabilities at the type level.

## A Practical Example: Transformers
Consider a scenario where you have a `Transformer` that can be in one of two states:

A `DieselTruck` state where it can honk and transform.
An `OptimusPrime` state where it can roll out.
We want to enforce at compile time that you can't "roll out" until you've "transformed," and you can't "transform" once you've already become Optimus Prime. Phantom types provide a clean, compile-time safe way to model these states.

```rust
use std::marker::PhantomData;

struct Transformer<T> {
_type: PhantomData<T>
}

struct DieselTruck {}
struct OptimusPrime {}

// Only DieselTrucks can honk and transform
impl Transformer<DieselTruck> {
    pub fn honk(&self) -> &str {
        "Honk! Honk!"
    }

    pub fn transform(self) -> Transformer<OptimusPrime> {
        Transformer { _type: PhantomData }
    }
}

// Only Optimus Prime can roll out
impl Transformer<OptimusPrime> {
    pub fn roll_out(&self) -> &str {
        "Roll Out!"
    }
}
```
## Ensuring Compile-Time Guarantees
With the Transformer struct, the type system enforces the logical progression of states:

A `Transformer<DieselTruck>` can honk and transform into `Transformer<OptimusPrime>`.
Once transformed into Transformer<OptimusPrime>, you can no longer honk or transform—it’s simply not allowed at the type level. Instead, now you can roll_out(), a capability exclusive to the Optimus Prime state.
If you try to call roll_out() on a DieselTruck or honk() on an OptimusPrime, your code won’t compile. This is not just a runtime check—it’s impossible to write code that compiles incorrectly. The type system catches these logical errors early, making your code more robust.

## Testing It Out
```rust
#[cfg(test)]
mod tests {
use super::*;

    #[test]
    fn test_phantom_type() {
        let diesel_truck = Transformer::<DieselTruck> {
            _type: PhantomData
        };

        // This works
        println!("{}", diesel_truck.honk());

        // Transform into OptimusPrime
        let optimus_prime = diesel_truck.transform();

        // Now that we're OptimusPrime, we can't honk anymore.
        // This will not compile!
        // println!("{}", optimus_prime.honk());
        // But we can roll out!
        println!("{}", optimus_prime.roll_out());
    }
}
```
Try uncommenting calls to invalid methods and you’ll see the compiler errors that prevent you from making improper state transitions.

## Why Use Phantom Types?
*Compile-Time Safety*: Phantom types give the compiler extra information, preventing you from using APIs incorrectly.
*Clearer State Management*: By encoding states as distinct types, it becomes clearer what operations are possible at any given time.
*Zero Runtime Overhead*: Since `PhantomData` doesn’t store actual data, it adds no runtime cost—just extra compile-time checks.


