///|
struct ToList[T] {
  to_list : @immut/list.T[T]
}

///|
impl[T : Vertex] Graph for ToList[T] with empty() {
  { to_list: @immut/list.Nil }
}

///|
impl[T : Vertex] Graph for ToList[T] with vertex(v) {
  { to_list: @immut/list.singleton(T::extract(v)) }
}

///|
impl[T : Vertex] Graph for ToList[T] with overlay(a, b) {
  { to_list: a.to_list + b.to_list }
}

///|
impl[T : Vertex] Graph for ToList[T] with connect(a, b) {
  { to_list: a.to_list + b.to_list }
}
