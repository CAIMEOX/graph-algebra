///|
enum GraphData[A] {
  Vertex(A)
  Overlay(GraphData[A], GraphData[A])
  Connect(GraphData[A], GraphData[A])
  Empty
}

///|
impl[A : Vertex] Graph for GraphData[A] with empty() { Empty }

///|
impl[A : Vertex] Graph for GraphData[A] with vertex(v) { Vertex(A::unwrap(v)) }

///|
impl[A : Vertex] Graph for GraphData[A] with overlay(a, b) { Overlay(a, b) }

///|
impl[A : Vertex] Graph for GraphData[A] with connect(a, b) { Connect(a, b) }

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
  logger.write_object(x.to_string())
}

///|
pub fn fold[A : Graph, V : Vertex](self : GraphData[V]) -> A {
  match self {
    Vertex(v) => Graph::vertex(v.wrap())
    Overlay(a, b) => Graph::overlay(a.fold(), b.fold())
    Connect(a, b) => Graph::connect(a.fold(), b.fold())
    Empty => Graph::empty()
  }
}
