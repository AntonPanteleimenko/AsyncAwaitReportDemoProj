# New structured concurrency changes

Async await is part of the new structured concurrency changes that arrived in Swift 5.5 during WWDC 2021. Concurrency in Swift means allowing multiple pieces of code to run at the same time. This is a very simplified description, but it should give you an idea already how important concurrency in Swift is for the performance of your apps. With the new async methods and await statements, we can define methods performing work asynchronously.
You can find more information in a [presentation](https://docs.google.com/presentation/d/1jk9Jyf7-EleHu08slPAF0QkMBI6Emy0k/edit?usp=sharing&ouid=103572584375496531035&rtpof=true&sd=true) and [video](https://google.com).

## Before Async/Await

This year, WWDC came with a bunch of new features and updates. Maybe one of the most expected was the introduction of the new concurrency system by using async/await syntax. This is a huge improvement in the way that we write asynchronous code.
Imagine that we are working on an app for a grocery store and, we want to display its list of products. We are probably going to have something like this:

```Ruby
func fetchProducts(_ completion: @escaping([Product]) -> Void) {...}

var products = [Product]()
fetchProducts { [weak self] products in
    guard let strongSelf = self else { return }
    strongSelf.products.append(contentsOf: products)
}
```

A pretty standard and well-known code using completion blocks. Now suppose that the grocery store has, once in a while, some kind of offers for some products (e.g., "Take 2, pay 1"). And, we want to hold a list with these offers. Let's adjust our code by creating a new function to retrieve a String with the promotion text, given a specific product.

```Ruby
func fetchProducts(_ completion: @escaping([Product]) -> Void) {...}
func getOffer(for product: Int, @escaping(String) -> Void) {...}

typealias ProductOffer = (productId: Int, offer: String)
var products = [Product]()
var offers = [ProductOffer]()

fetchProducts { [weak self] products in
    guard let strongSelf = self else { return }

    for product in products {
        strongSelf.products.append(product)

        getOffer(for: product.id) { [weak self] offerText in
            guard let strongSelf = self else { return }
            let productOffer = ProductOffer(productId: product.id, offer: offerText)
            strongSelf.offers.append(productOffer)
        }
    }
}
```

We only have two nested closures for a simple feature, and you can see that our code starts to get a little messed up.

## Async/Await

From Swift 5.5 onwards, we can start using async/await functions to write asynchronous code without using completion handlers to returns values. Instead, we are allowed to return the values in the return object directly.

To mark a function as asynchronous, we only have to put the keyword async before the return type.

```Ruby
func fetchProducts() async -> [Product] {...}
func getOffer(for product: Int) async -> String {...}
```

This is much easier and simple to read, but the best part comes from the caller's side. When we want to use the result of a function marked as async, we need to make sure that its execution is already completed. To make this possible, we need to write the await keyword in front of the function call. By doing this, the current execution will be paused until the result is available for its use.

```Ruby
let products = await fetchProducts()

for product in products {
    let offerText = await getOffer(for: product.id)

    if !offerText.isEmpty {
        let productOffer = ProductOffer(productId: product.id, offer: offerText)
        offers.append(productOffer)
    }
}
```

Although, if we want to execute other tasks while the async function is being executed, we should put the keyword async in front of the variable (or let) declaration. In this case, the await keyword will need to be placed in front of the variable (or let) where we are accessing the result of the async function.

```Ruby
async let products = fetchProducts()
...
// Do some work
...
print(await products)
```
![](https://i.ytimg.com/vi/esmf26aGz4s/maxresdefault.jpg)

### Parallel Asynchronous Functions

Now imagine that in our app, we want to fetch products by category—for example, just the frozen products. Let's go ahead and make the adjustments to our code.

```Ruby
enum ProductCategory {
    case frozen
    case meat
    case vegetables
    ...
}

func fetchProducts(fromCategory category: ProductCategory) async -> [Product] {...}

let frozenProducts = await fetchProducts(fromCategory: .frozen)
let meatProducts = await fetchProducts(fromCategory: .meat)
let vegetablesProducts = await fetchProducts(fromCategory: .vegetals)
This is ok, but the code will run in serial mode, which means that we won't start fetching the meat products until the frozen products are retrieved. Same for the vegetables. Remember, we write the await keyword if we want to pause our execution until the function completes its work. However, in this particular scenario, we could start fetching the three categories at the same time, running in parallel.

In order to accomplish this, we need to write the async keyword in front of the var (or let) declaration and use the await keyword when we want to use it.

async let frozenProducts = await fetchProducts(fromCategory: .frozen)
async let meatProducts = await fetchProducts(fromCategory: .meat)
async let vegetablesProducts = await fetchProducts(fromCategory: .vegetables) 

....

let products = await [frozenProducts, meatProducts, vegetablesProducts]
```
This is ok, but the code will run in serial mode, which means that we won't start fetching the meat products until the frozen products are retrieved. Same for the vegetables. Remember, we write the await keyword if we want to pause our execution until the function completes its work. However, in this particular scenario, we could start fetching the three categories at the same time, running in parallel.

In order to accomplish this, we need to write the async keyword in front of the var (or let) declaration and use the await keyword when we want to use it.

```Ruby
async let frozenProducts = await fetchProducts(fromCategory: .frozen)
async let meatProducts = await fetchProducts(fromCategory: .meat)
async let vegetablesProducts = await fetchProducts(fromCategory: .vegetables) 

....

let products = await [frozenProducts, meatProducts, vegetablesProducts]
```

### Error handlers

Our fetching functions might have some errors that make it impossible to return the expected data values. How do we handle this in our async/await context?

We have a couple of options. The first one is to return the well-known Result object.

```Ruby
func fetchProducts() async -> Result<[Product], Error> {...}

let result = try await fetchProducts()
switch result {
    case .success(let products):
        // Handle success
    case .failure(let error):
        // Handle error
}
Another one is to use the try/catch approach.

func fetchProducts() async throws -> [Product[ {...}
...
do {
    let products = try await fetchProducts()
} catch {
    // Handle the error
}
```

The main benefit that we had when using the Result type was to improve our completion handlers. In addition to that, we got a cleaner code at the moment we used the result, being able to switch between success and failure cases.

On the other hand, the use of throw errors adds extra readability in the function's definition because we only need to put the result type that the function will return. The errors handling is hidden in the function's implementation.

## Async/Await vs. Completion Handlers

As we saw in the previous sections, the use of async/await syntax comes with a lot of improvements in contrast with using completion blocks. Let's make a quick recap.

Advantages

1. Avoid the Pyramid of Doom problem with nested closures;
2. Reduction of code;
3. Easier to read;
4. Safety. With async/await, a result is guaranteed, while completion blocks might or might not be called.

Disadvantages

1. It's only available from Swift 5.5 and iOS 15 onwards.

### Actors

Take a look at the following example, just a simple Order class in which we will be adding products and eventually make the checkout.

```Ruby
class Order {
    
    var products = [Product]()
    var finalPrice = 0

    func addProduct(_ product: Product) {
        products.append(product)
        finalPrice += product.price
    }
}
```

If we are in a single-thread application, this code is just fine. But what happens if we have multiple threads that can access our order's final price?

1. We are on the product list and add some specific products to our order. The app will call the addProduct function;
2. The product is added to our order's product list;
3. Before the final price gets updated, the user tries to checkout;
4. The app will read the final price of our order;
4. The addProduct function completes and updates the final price. But the user already checkout and paid less than they should;
6. This problem is known as Data Races when some particular resource could be accessed from multiple parts of the app's code.

Actors, also introduced in Swift 5.5 and iOS 15, resolve this problem for us. An Actor is basically like a class but with a few key differences that make them thread-safe:

1. Only allow accessing their state by one task at a time;
2. Stored properties and functions can only be access from outside the Actor if the operation is performed asynchronously;
3. Stored properties can't be written from outside the Actor.

On the downside:

1. Actors do not support inheritance.

You can think about the Actors like a similar solution of the semaphores) concept.

To create one, we just need to use the actor keyword.

```Ruby
actor Order {
    
    var products = [Product]()
    var finalPrice = 0

    func addProduct(_ product: Product) {
        products.append(product)
        finalPrice += product.price
    }
}
```

And we can create an instance using the same initializer syntax as structures and classes. If we want to access the final price, we must do it using the keyword await (because outside the actor's scope, we are only allowed to access the properties asynchronously).

```Ruby
print(await order.finalPrice)
```

### Sendable and @Sendable closures 

Sendable and @Sendable are part of the concurrency changes that arrived in Swift 5.5 and address a challenging problem of type checking values passed between structured concurrency constructs and actor messages.

The Sendable protocol and closure indicate whether the public API of the passed values passed thread-safe to the compiler. A public API is safe to use across concurrency domains when there are no public mutators, an internal locking system is in place, or mutators implement copy on write like with value types.

Many types of the standard library already support the Sendable protocol, taking away the requirement to add conformance to many types. As a result of the standard library support, the compiler can implicitly create support for your custom types.

Once we create a value type struct with a single property of type int, we implicitly get support for the Sendable protocol:

```Ruby
// Implicitly conforms to Sendable
struct Article {
    var views: Int
}
```

At the same time, the following class example of the same article would not have implicit conformance:

```Ruby
// Does not implicitly conform to Sendable
class Article {
    var views: Int
}
```

Implicit conformance takes away a lot of cases in which we need to add conformance to the Sendable protocol ourselves. However, there are cases in which the compiler does not add implicit conformance while we know that our type is thread-safe.

Common examples of types that are not implicitly sendable but can be marked as such are immutable classes and classes with internal locking mechanisms:

```Ruby
/// User is immutable and therefore thread-safe, so can conform to Sendable
final class User: Sendable {
    let name: String

    init(name: String) { self.name = name }
}
```

Functions can be passed across concurrency domains and will therefore require sendable conformance too. However, functions can’t conform to protocols which is why the @Sendable attribute is introduced. Examples of functions that you can pass around are global function declarations, closures, and accessors like getters and setters.
By using the @Sendable attribute we will tell the compiler that no extra synchronization is needed as all captured values in the closure are thread-safe to work with. A typical example would be using closures from within Actor isolation:

```Ruby
actor ArticlesList {
    func filteredArticles(_ isIncluded: @Sendable (Article) -> Bool) async -> [Article] {
        // ...
    }
}
```

### Nonisolated and isolated keywords

[SE-313](https://github.com/apple/swift-evolution/blob/main/proposals/0313-actor-isolation-control.md). introduced the nonisolated and isolated keywords as part of adding actor isolation control. Actors are a new way of providing synchronization for shared mutable states with the new concurrency framework.

By default, each method of an actor becomes isolated, which means you’ll have to be in the context of an actor already or use await to wait for approved access to actor contained data.
It’s typical to run into errors with actors like the ones below:

1. Actor-isolated property ‘balance’ can not be referenced from a non-isolated context;
2. Expression is ‘async’ but is not marked with ‘await’.

Both errors have the same root cause: actors isolate access to its properties to ensure mutually exclusive access.

Take the following bank account actor example:

```Ruby
actor BankAccountActor {
    enum BankError: Error {
        case insufficientFunds
    }
    
    var balance: Double
    
    init(initialDeposit: Double) {
        self.balance = initialDeposit
    }
    
    func transfer(amount: Double, to toAccount: BankAccountActor) async throws {
        guard balance >= amount else {
            throw BankError.insufficientFunds
        }
        balance -= amount
        await toAccount.deposit(amount: amount)
    }
    
    func deposit(amount: Double) {
        balance = balance + amount
    }
}
```

Actor methods are isolated by default but not explicitly marked as so. You could compare this to methods that are internal by default but not marked with an internal keyword. Under the hood, the code looks as follows:

```Ruby
isolated func transfer(amount: Double, to toAccount: BankAccountActor) async throws {
    guard balance >= amount else {
        throw BankError.insufficientFunds
    }
    balance -= amount
    await toAccount.deposit(amount: amount)
}

isolated func deposit(amount: Double) {
    balance = balance + amount
}
```

Though, marking methods explicitly with the isolated keyword like this example will result in the following error:

```Ruby
‘isolated’ may only be used on ‘parameter’ declarations
```

We can only use the isolated keyword with parameter declarations.

Using the isolated keyword for parameters can be pretty nice to use less code for solving specific problems. The above code example introduced a deposit method to alter the balance of another bank account.

We could get rid of this extra method by marking the parameter as isolated instead and directly adjust the other bank account balance:

```Ruby
func transfer(amount: Double, to toAccount: isolated BankAccountActor) async throws {
    guard balance >= amount else {
        throw BankError.insufficientFunds
    }
    balance -= amount
    toAccount.balance += amount
}
```

The result is using less code which might make your code easier to read.

Multiple isolated parameters are prohibited but allowed by the compiler for now:

```Ruby
func transfer(amount: Double, from fromAccount: isolated BankAccountActor, to toAccount: isolated BankAccountActor) async throws {
    // ..
}
```

Though, the original proposal indicated this was not allowed, so a future release of Swift might require you to update this code.

Marking methods or properties as nonisolated can be used to opt-out to the default isolation of actors. Opting out can be helpful in cases of accessing immutable values or when conforming to protocol requirements.

In the following example, we’ve added an account holder name to the actor:

```Ruby
actor BankAccountActor {
    
    let accountHolder: String

    // ...
}
```

The account holder is an immutable let and is therefore safe to access from a non-isolated environment. The compiler is smart enough to recognize this state, so there’s no need to mark this parameter as nonisolated explicitly.

However, if we introduce a computed property accessing an immutable property, we have to help the compiler a bit. Let’s take a look at the following example:

```Ruby
actor BankAccountActor {

    let accountHolder: String
    let bank: String

    var details: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }

    // ...
}
```

If we were to print out details right now, we would run into the following error:

Actor-isolated property ‘details’ can not be referenced from a non-isolated context

Both bank and accountHolder are immutable properties, so we can explicitly mark the computed property as nonisolated and solve the error:

```Ruby
actor BankAccountActor {

    let accountHolder: String
    let bank: String

    nonisolated var details: String {
        "Bank: \(bank) - Account holder: \(accountHolder)"
    }

    // ...
}
```

### Conclusion

Definitely async/await brings to the table an easier way to write asynchronous code, removing the need to use completion blocks. In addition, we get more readable and flexible code if our application starts scaling up.

However, the minimum iOS deployment target will be an entry barrier for most of us unless you start a project from scratch, in which case is highly recommended to wait until the official release of iOS 15 + Xcode 13 + Swift 5.5 to take full advantage of the new concurrency system.

## Useful Links

[Async await in Swift explained with code examples](https://www.avanderlee.com/swift/async-await/)

[Swift Concurrency Manifesto](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782)

[Знакомимся с async/await в Swift](https://habr.com/ru/company/citymobil/blog/571360/)

[Meet Swift Concurrency](https://developer.apple.com/news/?id=2o3euotz)


## Developed By

* Panteleimenko Anton, CHI Software
* Kosyi Vlad, CHI Software

## License

Copyright 2021 CHI Software.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
