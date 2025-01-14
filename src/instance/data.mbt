///|
typealias Vertex = @alga.Vertex

///|
typealias Graph = @alga.Graph

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
pub fn connect[A](a : GraphData[A], b : GraphData[A]) -> GraphData[A] {
  Connect(a, b)
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

test "graph functor" {
  let a = [1, 2, 3, 4]
  let x : @alga.GraphFunctor[GraphData[Int], Int, Int] = @alga.clique(a)
  let x1 : @alga.GraphFunctor[GraphData[Unit], Int, Unit] = @alga.clique(a)
  let y = x.graph_map(fn(p) { p + 100 })
  let y1 = x1.graph_map(fn(_) { () })
  inspect!(y, content="(((($e -> 101) -> 102) -> 103) -> 104)")
  inspect!(y1, content="(((($e -> ()) -> ()) -> ()) -> ())")
}

test "graph monad" {
  let x = [1, 2, 3, 4]
  let y : @alga.GraphMonad[GraphData[Int], Int] = @alga.clique(x)
  let z = y.bind(fn(v) { @alga.vertices([v, v - 1, v + 1]) })
  let w = y.bind(fn(v) { @alga.clique([v, v + 1, v + 2]) })
  inspect!(
    z,
    content="(((($e -> $e + 1 + 0 + 2) -> $e + 2 + 1 + 3) -> $e + 3 + 2 + 4) -> $e + 4 + 3 + 5)",
  )
  inspect!(
    w,
    content="(((($e -> ((($e -> 1) -> 2) -> 3)) -> ((($e -> 2) -> 3) -> 4)) -> ((($e -> 3) -> 4) -> 5)) -> ((($e -> 4) -> 5) -> 6))",
  )
}

test "induce" {
  let x = [1, 2, 3, 4]
  let y : @alga.GraphMonad[GraphData[Int], Int] = @alga.clique(x)
  let z = y.induce(fn(v) { v % 2 == 0 })
  inspect!(z, content="(((($e -> $e) -> 2) -> $e) -> 4)")
}

test "string vertex" {
  let x : Array[String] = ["a", "b", "c"]
  let y : GraphData[String] = @alga.vertices(x)
  let y1 : GraphData[String] = @alga.clique(x)
  let z : Relation[String] = @alga.vertices(x)
  inspect!(y, content="$e + a + b + c")
  inspect!(y1, content="((($e -> a) -> b) -> c)")
  inspect!(
    z,
    content=
      #|Rel[@immut/sorted_set.of(["a", "b", "c"]), @immut/sorted_set.of([])]
    ,
  )
}

test "int vertex" {
  let x : Array[Int] = [1, 2, 3]
  let y : GraphData[Int] = @alga.vertices(x)
  let y1 : GraphData[Int] = @alga.clique(x)
  let z : Relation[Int] = @alga.vertices(x)
  let z1 : Relation[Int] = @alga.clique(x)
  inspect!(y, content="$e + 1 + 2 + 3")
  inspect!(y1, content="((($e -> 1) -> 2) -> 3)")
  inspect!(
    z,
    content=
      #|Rel[@immut/sorted_set.of([1, 2, 3]), @immut/sorted_set.of([])]
    ,
  )
  inspect!(
    z1,
    content="Rel[@immut/sorted_set.of([1, 2, 3]), @immut/sorted_set.of([(1, 2), (1, 3), (2, 3)])]",
  )
}
