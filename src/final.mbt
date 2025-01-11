///|
enum GraphData[A] {
  Vertex(A)
  Overlay(GraphData[A], GraphData[A])
  Connect(GraphData[A], GraphData[A])
  Empty
} derive(Eq)

///|
impl[V : Vertex] Graph for GraphData[V] with empty() { Empty }

///|
impl[V : Vertex] Graph for GraphData[V] with vertex(v) { Vertex(V::extract(v)) }

///|
impl[V : Vertex] Graph for GraphData[V] with overlay(a, b) { Overlay(a, b) }

///|
impl[V : Vertex] Graph for GraphData[V] with connect(a, b) { Connect(a, b) }

///|
impl[A : Show] Show for GraphData[A] with to_string(self) {
  match self {
    Vertex(v) => v.to_string()
    Overlay(a, b) => "\{a} + \{b}"
    Connect(a, b) => "(\{a} -> \{b})"
    Empty => "$e".to_string()
  }
}

///|
impl[A : Show] Show for GraphData[A] with output(x, logger) {
  logger.write_string(x.to_string())
}

///|
pub fn pure[A : Vertex](v : A) -> GraphData[A] {
  Vertex(v)
}

///|
pub fn empty[A]() -> GraphData[A] {
  Empty
}

///|
pub fn overlay[A](a : GraphData[A], b : GraphData[A]) -> GraphData[A] {
  Overlay(a, b)
}

///|
pub fn fold[A : Graph, V : Vertex](self : GraphData[V]) -> A {
  match self {
    Vertex(v) => Graph::vertex(v.rep())
    Overlay(a, b) => Graph::overlay(a.fold(), b.fold())
    Connect(a, b) => Graph::connect(a.fold(), b.fold())
    Empty => Graph::empty()
  }
}

///|
pub fn fold_graph[V, B](
  self : GraphData[V],
  empty : B,
  vertex : (V) -> B,
  overlay : (B, B) -> B,
  connect : (B, B) -> B
) -> B {
  match self {
    Vertex(va) => vertex(va)
    Overlay(a, b) =>
      overlay(
        a.fold_graph(empty, vertex, overlay, connect),
        b.fold_graph(empty, vertex, overlay, connect),
      )
    Connect(a, b) =>
      connect(
        a.fold_graph(empty, vertex, overlay, connect),
        b.fold_graph(empty, vertex, overlay, connect),
      )
    Empty => empty
  }
}

///|
pub fn map[V, W](self : GraphData[V], f : (V) -> W) -> GraphData[W] {
  match self {
    Vertex(v) => Vertex(f(v))
    Overlay(a, b) => Overlay(a.map(f), b.map(f))
    Connect(a, b) => Connect(a.map(f), b.map(f))
    Empty => Empty
  }
}

///|
pub fn bind[V, W](self : GraphData[V], f : (V) -> GraphData[W]) -> GraphData[W] {
  match self {
    Vertex(v) => f(v)
    Overlay(a, b) => Overlay(a.bind(f), b.bind(f))
    Connect(a, b) => Connect(a.bind(f), b.bind(f))
    Empty => Empty
  }
}

///|
pub fn is_empty[A](self : GraphData[A]) -> Bool {
  let and = fn(x, y) { x && y }
  self.fold_graph(true, fn { _ => true }, and, and)
}

///|
pub fn has_vertex[A : Eq](self : GraphData[A], v : A) -> Bool {
  let or = fn(x, y) { x || y }
  self.fold_graph(false, fn(x) { x == v }, or, or)
}
