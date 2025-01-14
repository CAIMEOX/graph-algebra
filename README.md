# Algebraic Graph

**Alga-Moon** is a library for algebraic construction and manipulation of graphs in MoonBit. See [this functional pearl](https://dl.acm.org/doi/10.1145/3122955.3122956) the motivation behind the library, the underlying theory and implementation details. 
This is a MoonBit port of the [Alga](https://github.com/snowleopard/alga). (Tthere are some differences in the API and the implementation caused by the differences between Haskell and MoonBit type system)

## Installation

The package has been published to the MoonBit package registry. You can install it using the following command:

```bash
moon add CAIMEOX/graph-algebra 
```

## Main Idea

Consider the following data type, which is defined in the root package of the module:

```moonbit
enum GraphData[A] {
  Empty
  Vertex(A)
  Overlay(GraphData[A], GraphData[A])
  Connect(GraphData[A], GraphData[A])
}
```

The paper shows that these four constructors are sufficient to represent any graph **(V, E)** by defining the following interpretations:
- `Empty` represents an empty graph: **(∅, ∅)**
- `Vertex(a)` represents a graph with a single vertex `a`: **({a}, ∅)**
- `Overlay(x, y)` represents the disjoint union of two graphs `x` and `y`: **(V(x) ∪ V(y), E(x) ∪ E(y))**
- `Connect(x, y)` represents the graph obtained by adding all possible edges between the vertices of `x` and `y`: **(V(x) ∪ V(y), E(x) ∪ E(y) ∪ { (a, b) | a ∈ V(x), b ∈ V(y) }**

Notice that **every** data structure that owns these four constructors (and satisfies some additional algebraic laws) can be interpreted as a graph. This is the main idea behind the library, to capture this idea, we define the `Graph` trait:

```moonbit
trait Graph {
  empty() -> Self
  vertex(VertRep) -> Self
  overlay(Self, Self) -> Self
  connect(Self, Self) -> Self
}
```

There is a tricky part in the definition of `vertex` method, which requires a type parameter `VertRep`. Due to the lackness of associated types in MoonBit, here we separated the vertex representation from the graph type:

```moonbit
type VertRep Error
 
trait Vertex {
  extract(VertRep) -> Self
  rep(Self) -> VertRep
}
```

We leverage the extensible `Error` type to represent **any** valid vertex and provide a `Vertex` trait to handle the vertices of a graph. The `extract` method extracts the vertex from its universal representation, while the `rep` method converts the vertex back to its universal representation.

The interfaces in this library are designed to be as general as possible: operations are only requires the `Graph` and `Vertex` trait, for instance:

```moonbit
fn singleton[A : Graph, V : Vertex](v : V) -> A
```

`singleton` converts a given vertex into a graph with that vertex as the only element. The `Graph` and `Vertex` traits constrain the type parameters `A` and `V`, respectively. Another interesting example is the `is_subgraph` function:

```moonbit
pub fn is_subgraph[A : Graph + Eq](x : A, y : A) -> Bool {
  x.overlay(y) == y
}
```

It is trivial to figure out how it works: if `x` is a subgraph of `y`, then the overlay of `x` and `y` should be equal to `y`. The `Eq` trait is used to compare the graphs.

## Usage

You need two recipes to use this library: the implementation of `Graph` and `Vertex`. 
We provide a deeply embedded implementation of `Graph` called `GraphData` and some instances of `Vertex`.

## Further Reading
- [Algebraic graphs with class (functional pearl)](https://dl.acm.org/doi/10.1145/3122955.3122956)
- [alga (haskell)](https://github.com/snowleopard/alga)