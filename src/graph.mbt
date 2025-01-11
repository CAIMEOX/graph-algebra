///|
trait Graph {
  empty() -> Self
  vertex(VertRep) -> Self
  overlay(Self, Self) -> Self
  connect(Self, Self) -> Self
}

///|
pub fn vertices[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(transform).fold(init=Graph::empty(), Graph::overlay)
}

///|
pub fn connects[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(transform).fold(init=Graph::empty(), Graph::connect)
}

///|
pub fn transform[A : Graph, V : Vertex](v : V) -> A {
  Graph::vertex(v.rep())
}

///|
pub fn edge[A : Graph, V : Vertex](x : V, y : V) -> A {
  Graph::connect(Graph::vertex(x.rep()), Graph::vertex(y.rep()))
}

///|
pub fn clique[A : Graph, V : Vertex](x : Array[V]) -> A {
  x.map(transform).fold(init=Graph::empty(), Graph::connect)
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
struct GraphFunctor[G, V] {
  g_for : ((V) -> V) -> G
}

///|
impl[V : Vertex, G : Graph] Graph for GraphFunctor[G, V] with empty() {
  { g_for: fn(_) { G::empty() } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphFunctor[G, V] with vertex(x) {
  { g_for: fn(f) { G::vertex(f(V::extract(x)).rep()) } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphFunctor[G, V] with overlay(x, y) {
  { g_for: fn(f) { G::overlay(graph_map(x, f), graph_map(y, f)) } }
}

///|
impl[V : Vertex, G : Graph] Graph for GraphFunctor[G, V] with connect(x, y) {
  { g_for: fn(f) { G::connect(graph_map(x, f), graph_map(y, f)) } }
}

///|
fn graph_map[G : Graph, V : Vertex](
  self : GraphFunctor[G, V],
  f : (V) -> V
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
