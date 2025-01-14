///|
pub trait Graph {
  empty() -> Self
  vertex(VertRep) -> Self
  overlay(Self, Self) -> Self
  connect(Self, Self) -> Self
}

test "graph functor" {
  let a = [1, 2, 3, 4]
  let x : GraphFunctor[GraphData[Int], Int, Int] = clique(a)
  let x1 : GraphFunctor[GraphData[Unit], Int, Unit] = clique(a)
  let y = x.graph_map(fn(p) { p + 100 })
  let y1 = x1.graph_map(fn(_) { () })
  inspect!(y, content="(((($e -> 101) -> 102) -> 103) -> 104)")
  inspect!(y1, content="(((($e -> ()) -> ()) -> ()) -> ())")
}

///|
pub fn vertices[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(singleton).fold(init=Graph::empty(), Graph::overlay)
}

///|
pub fn connects[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(singleton).fold(init=Graph::empty(), Graph::connect)
}

///|
pub fn singleton[A : Graph, V : Vertex](v : V) -> A {
  Graph::vertex(v.rep())
}

///|
pub fn edge[A : Graph, V : Vertex](x : V, y : V) -> A {
  Graph::connect(Graph::vertex(x.rep()), Graph::vertex(y.rep()))
}

///|
pub fn clique[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(singleton).fold(init=Graph::empty(), Graph::connect)
}

///|
pub fn edges[A : Graph, V : Vertex](e : Array[(V, V)]) -> A {
  e.map(fn { (x, y) => edge(x, y) }).fold(init=Graph::empty(), Graph::overlay)
}

///|
pub fn is_subgraph[A : Graph + Eq](x : A, y : A) -> Bool {
  x.overlay(y) == y
}

///|
pub fn path[A : Graph, V : Vertex](x : Array[V]) -> A {
  match x {
    [] => A::empty()
    [x] => A::vertex(x.rep())
    xs => {
      let av1 = xs[1:]
      let av2 = xs[:xs.length() - 1]
      av1.mapi(fn(i, v1) { (v1, av2[i]) }) |> edges
    }
  }
}

///|
struct GraphFunctor[G, V, W] {
  g_for : ((V) -> W) -> G
}

///|
impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with empty(

) {
  { g_for: fn(_) { G::empty() } }
}

///|
impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with vertex(
  x
) {
  { g_for: fn(f) { G::vertex(W::rep(f(V::extract(x)))) } }
}

///|
impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with overlay(
  x,
  y
) {
  { g_for: fn(f) { G::overlay(graph_map(x, f), graph_map(y, f)) } }
}

///|
impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with connect(
  x,
  y
) {
  { g_for: fn(f) { G::connect(graph_map(x, f), graph_map(y, f)) } }
}

///|
fn graph_map[G : Graph, V : Vertex, W : Vertex](
  self : GraphFunctor[G, V, W],
  f : (V) -> W
) -> G {
  (self.g_for)(f)
}

///|
struct GraphMonad[G, V] {
  bind : ((V) -> G) -> G
}

///|
pub fn bind[G : Graph, V : Vertex](self : GraphMonad[G, V], f : (V) -> G) -> G {
  (self.bind)(f)
}

///|
impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with empty() {
  { bind: fn(_) { G::empty() } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with vertex(x) {
  { bind: fn(f) { f(V::extract(x)) } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with overlay(x, y) {
  { bind: fn(f) { G::overlay(x.bind(f), y.bind(f)) } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with connect(x, y) {
  { bind: fn(f) { G::connect(x.bind(f), y.bind(f)) } }
}

test "graph monad" {
  let x = [1, 2, 3, 4]
  let y : GraphMonad[GraphData[Int], Int] = clique(x)
  let z = y.bind(fn(v) { vertices([v, v - 1, v + 1]) })
  let w = y.bind(fn(v) { clique([v, v + 1, v + 2]) })
  inspect!(
    z,
    content="(((($e -> $e + 1 + 0 + 2) -> $e + 2 + 1 + 3) -> $e + 3 + 2 + 4) -> $e + 4 + 3 + 5)",
  )
  inspect!(
    w,
    content="(((($e -> ((($e -> 1) -> 2) -> 3)) -> ((($e -> 2) -> 3) -> 4)) -> ((($e -> 3) -> 4) -> 5)) -> ((($e -> 4) -> 5) -> 6))",
  )
}

///|
pub fn induce[G : Graph, V : Vertex](
  self : GraphMonad[G, V],
  pred : (V) -> Bool
) -> G {
  self.bind(fn(v) { if pred(v) { G::vertex(v.rep()) } else { Graph::empty() } })
}

test "induce" {
  let x = [1, 2, 3, 4]
  let y : GraphMonad[GraphData[Int], Int] = clique(x)
  let z = y.induce(fn(v) { v % 2 == 0 })
  inspect!(z, content="(((($e -> $e) -> 2) -> $e) -> 4)")
}

///|
pub fn remove_vertex[G : Graph, V : Vertex + Eq](
  self : GraphMonad[G, V],
  v : V
) -> G {
  self.induce(fn(x) { x != v })
}

///|
pub fn biclique[A : Graph, V : Vertex](x : Array[V], y : Array[V]) -> A {
  match (x, y) {
    ([], ys) => vertices(ys)
    (xs, []) => vertices(xs)
    (xs, ys) => A::connect(vertices(xs), vertices(ys))
  }
}

///|
pub fn star[A : Graph, V : Vertex](x : V, ys : Array[V]) -> A {
  match ys {
    [] => A::vertex(x.rep())
    _ => A::connect(A::vertex(x.rep()), vertices(ys))
  }
}
