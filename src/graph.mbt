///|
pub(open) trait Graph {
  empty() -> Self
  vertex(VertRep) -> Self
  overlay(Self, Self) -> Self
  connect(Self, Self) -> Self
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
pub impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with empty(

) {
  { g_for: fn(_) { G::empty() } }
}

///|
pub impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with vertex(
  x
) {
  { g_for: fn(f) { G::vertex(W::rep(f(V::extract(x)))) } }
}

///|
pub impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with overlay(
  x,
  y
) {
  { g_for: fn(f) { G::overlay(graph_map(x, f), graph_map(y, f)) } }
}

///|
pub impl[W : Vertex, V : Vertex, G : Graph] Graph for GraphFunctor[G, V, W] with connect(
  x,
  y
) {
  { g_for: fn(f) { G::connect(graph_map(x, f), graph_map(y, f)) } }
}

///|
pub fn graph_map[G : Graph, V : Vertex, W : Vertex](
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
pub impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with empty() {
  { bind: fn(_) { G::empty() } }
}

///|
pub impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with vertex(x) {
  { bind: fn(f) { f(V::extract(x)) } }
}

///|
pub impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with overlay(x, y) {
  { bind: fn(f) { G::overlay(x.bind(f), y.bind(f)) } }
}

///|
pub impl[V : Vertex, G : Graph] Graph for GraphMonad[G, V] with connect(x, y) {
  { bind: fn(f) { G::connect(x.bind(f), y.bind(f)) } }
}

///|
pub fn induce[G : Graph, V : Vertex](
  self : GraphMonad[G, V],
  pred : (V) -> Bool
) -> G {
  self.bind(fn(v) { if pred(v) { G::vertex(v.rep()) } else { Graph::empty() } })
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
