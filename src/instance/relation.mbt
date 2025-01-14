///|
typealias Set[A] = @moonbitlang/core/immut/sorted_set.T[A]

///|
struct Relation[A] {
  domain : Set[A]
  relation : Set[(A, A)]
}

///|
fn cartesian[A : Compare](a : Set[A], b : Set[A]) -> Set[(A, A)] {
  a.map(fn { x => b.map(fn { y => (x, y) }) }).fold(init=Set::new(), Set::union)
}

///|
impl[A : Show] Show for Relation[A] with to_string(self) {
  "Rel[\{self.domain}, \{self.relation}]"
}

///|
impl[A : Show] Show for Relation[A] with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
impl[A : Compare + Vertex] Graph for Relation[A] with empty() {
  { domain: Set::new(), relation: Set::new() }
}

///|
impl[A : Compare + Vertex] Graph for Relation[A] with vertex(v) {
  { domain: Set::from_array([Vertex::extract(v)]), relation: Set::new() }
}

///|
impl[A : Compare + Vertex] Graph for Relation[A] with overlay(a, b) {
  {
    domain: Set::union(a.domain, b.domain),
    relation: Set::union(a.relation, b.relation),
  }
}

///|
impl[A : Compare + Vertex] Graph for Relation[A] with connect(a, b) {
  {
    domain: Set::union(a.domain, b.domain),
    relation: Set::union(a.relation, b.relation).union(
      cartesian(a.domain, b.domain),
    ),
  }
}
